# Go Guideline for AI Agents

This guideline consolidates idiomatic Go rules extracted from official Go and Google styleguide references (Effective Go, Code Review Comments, Package Names blog, Google Go Style Decisions, and Google Go Best Practices). It is intended to guide AI agents when writing or reviewing Go code.

## Core Principles

These meta-rules take priority over all section-specific rules below. When in conflict, follow Core Principles first.

1. **Follow existing codebase conventions first.** When these guidelines conflict with established patterns in the codebase, follow the codebase. Scan neighboring files before writing new code.
2. **Prefer simplicity.** Choose the simplest solution that works. Add complexity only when a concrete, demonstrated need justifies it.
3. **No speculative abstractions.** DO NOT create interfaces, wrappers, indirection layers, or new packages until a concrete need exists (second implementation, cycle-breaking, real boundary mocking).
4. **Make the zero value useful.** Design types so their zero value is immediately usable without explicit initialization.
5. **Accept interfaces, return structs.** Function parameters accept interfaces; return concrete types.
6. **Handle errors explicitly.** Never ignore errors. Never panic for flow control. Never log-and-return the same error.
7. **Keep packages focused.** Name packages by what they provide, not what they manage. One package = one clear concept.

## When in Doubt

Use this decision tree for common AI decision points:

| Decision | Default choice | Override when |
|---|---|---|
| Interface vs concrete type | Concrete type | 2+ implementations exist, or need to break a cycle |
| Pointer vs value receiver | Pointer receiver | Type is small, immutable, no pointer/mutex fields (e.g., `time.Time`) |
| New package vs inline | Inline into existing package | Concept is clearly distinct AND has multiple consumers |
| Functional options vs option struct vs params | Plain params (≤5) | Option struct when many callers pass many options; functional options when most callers pass nothing |
| `%w` vs `%v` in errors | `%v` (annotate) | `%w` when caller MUST inspect the wrapped error programmatically |
| New abstraction vs inline | Inline the code | Same logic appears 3+ times with variation |
| Export vs unexport | Unexport | The type/function is part of the public API contract |

## 1. Imports

- DO NOT rename imports unless there is a name collision. If a collision occurs, rename the most local or project-specific import. If the same package is renamed across files, use the same local name.
- Local names for renamed imports MUST follow package naming rules (lowercase, no underscores/mixedCaps). Generated protocol buffer packages MUST be renamed to remove underscores and use a `pb` suffix (`foopb "path/to/foo_go_proto"`); gRPC stubs use a `grpc` suffix. Use whole, descriptive words over very short names like `xpb`.
- Organize imports into ordered groups separated by blank lines: (1) standard library, (2) other project/vendored packages, (3) protocol buffer imports, (4) side-effect imports (`import _`).
- `import _ "pkg"` (side-effect import) MUST only be used in the `main` package of a program, or in tests that require it. DO NOT use blank imports in library packages. (Exception: `embed` with `//go:embed`.)
- `import . "pkg"` (dot import) is permitted ONLY in tests that cannot be part of the package under test due to circular dependencies. DO NOT use it elsewhere.

## 2. Commentary and Documentation

- Doc comments on exported declarations are REQUIRED. This requirement overrides any "minimize comments" guidance. Inline explanatory comments MUST be minimal — add them only to signal-boost non-obvious behavior, not to narrate what the code already says.
- Use `//` line comments by default. Reserve `/* */` block comments for package comments or to disable large regions.
- Comments immediately preceding a top-level declaration (no intervening blank line) are doc comments and are the primary documentation for that package/declaration.
- All top-level, exported names MUST have doc comments. Unexported type or function declarations with unobvious behavior MUST also have doc comments.
- Doc comments MUST be full sentences that begin with the name of the thing being described and end in a period. An article ("a", "an", "the") MAY precede the name:
  ```go
  // A Request represents a request to run a command.
  type Request struct { ... }

  // Encode writes the JSON encoding of req to w.
  func Encode(w io.Writer, req *Request) { ... }
  ```
- For unexported code with doc comments, follow the same convention (start with the name) so it can be exported later by simply renaming.
- Package comments MUST appear immediately above the package clause with no blank line, and there MUST be exactly one per package. They MUST begin with "Package <name>". For `package main`, acceptable forms include "Binary <name>", "Command <name>", "Program <name>", or "The <name> command/program" (capitalize the first word). If long or no primary file is obvious, place it in a `doc.go` file.
- Wrap long comment lines at ~80–100 columns. DO NOT cram large text onto a single line.

### Godoc formatting

- A blank line (an empty comment line) separates paragraphs.
- Indent lines by two additional spaces to format them verbatim (code snippets, lists, tables). Use runnable examples over code in comments.
- A single line that begins with a capital letter, contains no punctuation except parentheses and commas, and is followed by another paragraph, is formatted as a heading.
- DO NOT use decoration other than indentation.

### Documentation conventions

- **Parameters and configuration**: DO NOT document every parameter. Document only the error-prone or non-obvious ones and explain *why* they are interesting.
- **Contexts**: DO NOT document default context cancellation behavior (interrupts function, returns `ctx.Err()`). Document only when behavior differs: returns a non-`ctx.Err()` error, has other interruption mechanisms like `Stop`, or has special lifetime/lineage/attached-value expectations.
- **Concurrency**: Readers assume read-only operations are safe for concurrent use and mutating operations are not. Document only when the operation defies this assumption, synchronization is provided, or concurrent use is unexpectedly unsafe.
- **Cleanup**: Document any explicit cleanup the caller MUST perform (e.g., "Call Stop to release the Ticker's resources", "Caller MUST close resp.Body").
- **Errors**: Document significant sentinel error values or error types your functions return, including whether the type is a pointer receiver (so callers can use `errors.Is`/`errors.As`/`cmp` correctly). Document package-wide error conventions in the package comment.

### Signal boosting

- When a conditional looks like a common pattern but isn't (e.g., `err == nil` vs the more common `err != nil`), add a comment to draw attention to the difference (`if err == nil { // if NO error`).

## 3. Naming

- Visibility is determined by case: an initial uppercase letter exports the name; lowercase keeps it package-private.
- DO NOT use underscores in identifiers. Exceptions:
  1. `_test` suffix for black-box test packages (`linkedlist_test`).
  2. Test, Benchmark, and Example function names within `*_test.go` files.
  3. Low-level libraries interoperating with the OS or cgo (rare).
- Package names MUST be short, clear, lowercase, with no `under_scores` or `mixedCaps`, and MAY include digits (`k8s`, `oauth2`). Multi-word names stay unbroken and all lowercase (`tabwriter`, not `tabWriter` or `tab_writer`). Use simple nouns (`time`, `list`, `http`).
- Abbreviate only when the abbreviation is universally familiar to programmers (`strconv`, `syscall`, `fmt`). DO NOT abbreviate if it makes the name ambiguous.
- DO NOT steal good names from the user: avoid package names commonly used as variables in client code (`bufio`, not `buf`). Avoid names likely shadowed by common local variables (`usercount` is better than `count`).
- DO NOT create packages named `util`, `common`, `misc`, `helper`, `model`, `shared`, or `base`. If you cannot name a package by what it *is*, the boundary is wrong. Break up generic packages by pulling types/functions with common name elements into focused packages.
- DO NOT reuse names of popular standard packages (`io`, `http`). Packages frequently used together MUST have distinct names.
- DO NOT stutter: exported names MUST NOT repeat the package name or surrounding context. In package `chubby`, name the type `File` (`chubby.File`), not `ChubbyFile`. The HTTP server in `http` is `Server`, not `HTTPServer`. If a package exports one type named after itself, the constructor is `New` (`widget.New`, not `widget.NewWidget`). Omit the types of inputs/outputs, the receiver type, and pointer-ness from function/method names. Disambiguate with extra info only when needed (`WriteTextTo`, `WriteBinaryTo`).
- When a function in package `pkg` returns `pkg.Pkg` (or `*pkg.Pkg`), the function name MUST omit the type name. `New` in package `pkg` returns `pkg.Pkg` (`list.New()` -> `*list.List`). When a function returns `pkg.T` where `T` is not `Pkg`, include `T` for clarity (`time.NewTicker`, `time.ParseDuration`).
- Function naming: if a function returns a value, give it a noun-like name; if a function performs an action, give it a verb-like name. If identical functions differ only by type, include the type at the end (`ParseInt`, `ParseInt64`, `AppendInt`); omit the type for the clear "primary" version (`Marshal`, `MarshalText`).
- DO NOT use long names to compensate for poor naming. Write a helpful doc comment instead. If a line is too long, shorten the names rather than adding unnatural line breaks.
- Variable names MUST be short, especially for locals. Name length MUST be proportional to scope size and inversely proportional to number of uses: if file-scope, use multiple words; if single-line scope, one letter suffices. DO NOT drop letters to save typing (`Sandbox`, not `Sbx`). Omit type-like words (`users` not `userSlice`, `userCount` not `numUsers`) unless two forms of a value are in scope (`ageString` vs `age`). Omit words clear from context (in a `UserCount` method, `count` or `c` suffices).
- Single-letter names are useful to minimize repetition when the full word is obvious: `r` for `io.Reader`/`*http.Request`, `w` for `io.Writer`/`http.ResponseWriter`, `i` for indices, `x`/`y` for coordinates.
- Constants MUST use `MixedCaps` like all other names (exported uppercase, unexported lowercase). DO NOT use `MAX_PACKET_SIZE` or `kMaxBufferSize`. Name constants by their role, not their value (`MaxPacketSize`, not `Twelve = 12`); if a constant has no role apart from its value, DO NOT define it.
- DO NOT use a `Get`/`get` prefix for getters unless the underlying concept uses "get" (e.g., HTTP GET). Name the getter `Owner` for a field `owner`; name the setter `SetOwner`. For expensive/remote operations, use a word like `Compute` or `Fetch`.
- One-method interfaces MUST be named by the method plus an `-er` suffix: `Reader`, `Writer`, `Formatter`, `CloseNotifier`.
- DO NOT reuse canonical method names (`Read`, `Write`, `Close`, `Flush`, `String`) unless the method has the same signature and meaning. Conversely, if you implement the same semantics, use the same name and signature (`String`, not `ToString`).
- Use `MixedCaps` or `mixedCaps` for multiword names. DO NOT use underscores. An unexported constant is `maxLength`, not `MaxLength` or `MAX_LENGTH`.
- Initialisms/acronyms MUST have a consistent case: `URL` or `url`, never `Url`. Write `ServeHTTP` not `ServeHttp`, `appID` not `appId`. Use the exact same spelling everywhere in the codebase. Initialisms with lowercase letters in prose (`gRPC`, `iOS`, `DDoS`) appear as in prose when unexported (`gRPC`, `iOS`, `ddos`) and fully cased when exported (`GRPC`, `IOS`, `DDoS`).

### Test double and helper package naming

- Create test double packages by appending `test` to the original package name (e.g., `creditcardtest`). Mark them `testonly`.
- If doubles are needed for only one type, name the double concisely (`Stub`, not `StubService`). When multiple behaviors are needed, name by behavior (`AlwaysCharges`, `AlwaysDeclines`). When doubling multiple types, use explicit names (`StubService`, `StubStoredValue`).
- In tests, prefix double variable names when juxtaposed with production types for clarity (`spyCC`, not `cc`).

### Shadowing

- Reassigning the same variable via `:=` in the same scope (stomping) is permitted when the original value is no longer needed (e.g., `ctx, cancel := context.WithTimeout(ctx, ...)`).
- DO NOT use `:=` in a new scope to create a shadowed variable — code after the block refers to the original and this is bug-prone. To conditionally reassign, use `=` and pre-declare `var cancel func()`.
- DO NOT name variables the same as standard packages except in very small scopes. Conversely, DO NOT choose package names that force import renaming or shadow good variable names at the client side.

### DO NOT

- DO NOT use `SCREAMING_SNAKE_CASE` for constants (`MaxRetries`, not `MAX_RETRIES`).
- DO NOT use `Get`/`Set` prefixes for getters/setters unless the underlying concept uses those words.
- DO NOT use underscores in Go identifiers (except `_test` package suffix and test/benchmark function names).
- DO NOT use initialisms inconsistently within the same codebase (`URL` everywhere or `url` everywhere, never mixed).

## 4. Package Size and Layout

- If client code needs two values of different types to interact, put them in the same package. If related types are tightly coupled in implementation, place them in the same package to share unexported details without polluting the public API. Test: if a user MUST import both packages to use either meaningfully, combine them.
- DO NOT put an entire project in one package. When something is conceptually distinct, give it its own small package; the package name + exported type name form a meaningful identifier (`bytes.Buffer`, `ring.New`).
- DO NOT create single files with thousands of lines or many tiny files. There is no "one type, one file" convention. Files MUST be focused enough that a maintainer knows where to find things. Split large packages by grouping related code into separate files. A package with long documentation MAY use a `doc.go` containing only the package comment and clause.

### DO NOT

- DO NOT create packages named `util`, `common`, `misc`, `helper`, `model`, `shared`, or `base`. If you cannot name a package by what it *is*, the boundary is wrong.
- DO NOT put all project types in a single `types` or `models` package. Place types in the package that uses them.
- DO NOT create one-file-per-type layouts. Group related code by functionality, not by type kind.
- DO NOT create a package that has only one consumer and one type without a clear reason (e.g., cycle prevention). Inline it into the consumer package.
- DO NOT create a "manager", "handler", "service", or "controller" package that aggregates unrelated logic. Name packages by what they provide, not what they manage.

## 5. Control Structures

- `if` and `switch` accept an optional initialization statement: `if err := f(); err != nil { ... }`.
- `break` and `continue` accept an optional label. A `break` inside a `switch` within a `for` exits the `switch`, not the loop — use a label to exit the loop.
- Bodies of control structures MUST always be brace-delimited, even single-line bodies.
- When an `if` body ends in `break`/`continue`/`goto`/`return`, omit the unnecessary `else`.
- Keep the normal code path at minimal indentation. Handle errors first and return early:
  ```go
  if err != nil {
      // error handling
      return
  }
  // normal code
  ```
  DO NOT use `if err != nil { ... } else { /* normal code */ }`. If the `if` has an init statement and the variable is used for many lines, move the declaration to its own line so the normal path stays unindented.
- DO NOT line-break an `if` statement (it causes indentation confusion). Instead, extract boolean operands into local variables.
- `switch` and `case` statements MUST remain on a single line. If excessively long, indent all cases and separate with a blank line.
- DO NOT use `break` without a target label at the end of `switch` clauses — it is redundant (Go cases auto-break; use `fallthrough` for C-style behavior). Use a comment to clarify an empty clause.
- In conditionals comparing a variable to a constant, put the variable on the left (`if result == "foo"`, not `if "foo" == result`). DO NOT use "Yoda" conditions.

## 6. Functions

- Use multiple return values to return a result and an error. DO NOT use in-band error returns or out-parameters.
- DO NOT use in-band error values (e.g., `-1`, `nil`, `""`) to signal errors or missing results in exported functions. Return an additional value (an `error`, or a `bool` when no explanation is needed) as the final return value:
  ```go
  func Lookup(key string) (value string, ok bool)
  ```
  Values like `nil`, `""`, `0`, and `-1` are fine only when they are valid results the caller need not handle differently.
- Name result parameters when a function returns several values of the same type, when the meaning isn't clear from context, or when the caller MUST take a particular action on a result (e.g., `cancel func()`). DO NOT name result parameters just to avoid a `var` or to enable naked returns. Naked returns are permitted ONLY in functions under ~15 lines; otherwise use explicit returns. Naming a result to modify it in a deferred closure is always permitted.
- Use `defer` for resource cleanup (closing files, unlocking mutexes) so cleanup sits near the acquisition. Use `t.Cleanup` in tests for cleanup that runs when the test completes.
- Write synchronous functions — those that return their results directly or finish all callbacks/channel ops before returning. Synchronous functions keep goroutine lifetimes localized and let callers add concurrency when needed.
- DO NOT pass pointers as function arguments to save bytes. If a function refers to `x` only as `*x`, the argument MUST NOT be a pointer. Specifically, DO NOT pass `*string` or `*io.Reader`. Exceptions: large structs, small structs that might grow, or protocol buffer messages (handle by pointer).
- Function/method signatures MUST remain on a single line. DO NOT break function calls based solely on line length; factor out local variables to shorten call sites. DO NOT add inline comments on specific arguments — use an option struct or documentation. If a call is genuinely long/unusual, line breaks grouped by semantics are permitted. DO NOT break long string literals; break after the format string and place arguments on subsequent lines.

### Function argument lists

- DO NOT let a function signature exceed ~5 parameters. If parameters grow: split into several simpler functions (sharing an unexported implementation if needed), use an option struct, or use variadic options.
- **Option struct**: a struct collecting some/all arguments, passed as the last parameter. Use when: all callers need some options, many callers provide many options, or options are shared across functions. Contexts MUST NOT be included in option structs.
- **Variadic options**: exported functions returning closures passed to a `...Option` parameter. Use when: most callers need no options, options are infrequent/numerous, options take arguments or can fail, or third parties MAY define options. Options MUST accept parameters, not presence (`rpc.FailFast(enable bool)`, not `rpc.EnableFailFast()`). Process options in order; the last one wins for conflicts. The options struct MUST be unexported to restrict definitions to the package.

## 7. Contexts

- Pass `context.Context` explicitly as the first parameter:
  ```go
  func F(ctx context.Context, /* other arguments */) {}
  ```
- This convention also applies to test helpers (`func readTestFile(ctx context.Context, t *testing.T, path string)`). Exceptions where context comes from elsewhere: HTTP handlers (`req.Context()`), streaming RPC (stream's `Context()`), test functions (`(testing.TB).Context()`), and entrypoints (`main`, `init`) which use `context.Background()`.
- Always pass a `Context` even if the current implementation doesn't need one. Use `context.Background()` ONLY in entrypoint functions (`main`, `init`). In library code, always take a context from the caller.
- DO NOT add a `Context` member to a struct type. Add a `ctx` parameter to each method that needs it instead (exception: matching a required external interface signature). DO NOT create custom `Context` types or use interfaces other than `Context` in signatures — no exceptions.

## 8. Data

- Use `new(T)` or `&T{}` for zero-value pointers.
- Design types so their zero value is useful and ready to use without explicit initialization (e.g., `bytes.Buffer`, `sync.Mutex`).
- Use `make(T, args)` for slices, maps, and channels only. DO NOT use `new` for these.
- Use slices for sequential data, not arrays.
- When a function MAY reallocate a slice (e.g., `append`), return the new slice.
- Declare empty slices with `var t []string` (a nil slice) rather than `t := []string{}`. They are functionally equivalent (`len`/`cap` are zero). Use the nil slice, especially for return values. The exception is JSON encoding (nil -> `null`, `[]string{}` -> `[]`). DO NOT create APIs that force clients to distinguish nil from non-nil zero-length slices; use `len(s) == 0` to test emptiness, not `s == nil`.
- Use `[][]T` for 2D structures.
- Use the "comma ok" idiom `v, ok := m[k]` to distinguish missing keys from zero values; use `delete(m, k)` to remove entries. Maps MUST be explicitly initialized before modification; reading from a zero-value map is fine.
- Use `%v` for default formatting, `%+v` for field names, `%q` for quoted strings (use `%q` over manually quoting with `%s`), `%T` for type. Use `any` instead of `interface{}` in new code (Go 1.18+).
- To customize default formatting, define a `String() string` method. Avoid infinite recursion: convert the receiver to a basic type before passing it to `Sprintf` with a string verb.
- Pass a slice to a variadic function with `slice...` at the call site.
- DO NOT copy a value of type `T` if its methods are associated with the pointer type `*T` (e.g., `bytes.Buffer`, `sync.Mutex`). Use pointer types for structs that MUST not be copied.
- DO NOT use `math/rand`/`math/rand/v2` to generate keys, even throwaway ones. Use `crypto/rand.Reader` for random bytes, `crypto/rand.Text` for text, or encode random bytes with `encoding/hex`/`encoding/base64`.
- Specify channel direction where possible (`<-chan int`, `chan<- int`) to prevent programming errors and convey ownership.

### Composite literals

- Use composite literal syntax over building values field-by-field.
- Struct literals for types from **other packages** MUST specify field names. For package-local types, use field names when the struct has more than 3 fields or when it improves clarity.
- The closing brace of a multi-line literal MUST be on its own line at the same indentation as the opening brace; end the preceding line with a comma.
- "Cuddling" braces (no whitespace between `{ {` ) is permitted only when indentation matches and inner values are also literals/builders (not variables).
- Repeated type names MAY be omitted from slice/map literals. Zero-value fields MAY be omitted when clarity is not lost.

## 9. Variable Declarations

- Use `:=` when initializing a new variable with a non-zero value (`i := 42`, not `var i = 42`).
- Use zero-value declarations (`var coords Point`) when you want an empty value ready for later use (e.g., as unmarshal output). DO NOT use composite literals to declare zero values (`var coords = Point{X: 0, Y: 0}` is noisy).
- For a pointer to a zero value, both `new(T)` and `&T{}` are fine. Declare protobuf messages as pointer types (`new(pb.Bar)` or `&pb.Bar{}`), since `*pb.Something` satisfies `proto.Message` but `pb.Something` does not.
- Use composite literals when you know the initial elements. Preallocate (`make([]Node, 0, 16)`, `make(map[string]bool, shardSize)`) ONLY when sizes are known from empirical analysis. DO NOT preallocate speculatively.

## 10. Initialization

- Constants are compile-time and limited to numbers, runes, strings, and booleans. Use `iota` for enumerated constants.
- Variables MAY be initialized with runtime expressions, including calls like `os.Getenv`.
- Each source file MAY define niladic `init` functions. Use `init` ONLY for verification or repair of program state that cannot be expressed as a declaration.

## 11. Methods

- Name the receiver as a short (one or two letter) abbreviation of its type (e.g., `c` or `cl` for `Client`). DO NOT use `me`, `this`, or `self`. Keep the receiver name consistent across all methods of the type. If the receiver is unused, omit the name entirely (DO NOT use an underscore).
- Choosing value vs. pointer receiver — **correctness wins over speed**:
  - If the receiver is a `map`, `func`, or `chan`: use a value receiver.
  - If the receiver is a `slice` and the method doesn't reslice/reallocate: use a value receiver.
  - If the method MUST mutate the receiver: use a pointer receiver.
  - If the receiver is a struct containing a `sync.Mutex` or similar synchronizing field: use a pointer receiver.
  - If the receiver is a large struct or array: use a pointer receiver.
  - If the receiver is a struct/array with pointer fields that MAY be mutated: use a pointer receiver.
  - If the receiver is a small, naturally value-type struct with no mutable fields/pointers (e.g., `time.Time`), or a basic type: use a value receiver.
  - If none of the above apply: use a pointer receiver.
  - DO NOT mix receiver types across the methods of a type.
  - Decide value vs. pointer performance by profiling, not assumption.

## 12. Interfaces

- Keep interfaces small — one or two methods is idiomatic. Name one-method interfaces after the method plus `-er` suffix (`io.Writer`).
- A type implements an interface implicitly by providing its methods; no explicit declaration is required.
- DO NOT create an interface before a real need exists. DO NOT confuse the concept ("service", "repository") with the `interface` keyword. Reuse existing interfaces (especially generated RPC clients/servers) rather than wrapping them in new manual interfaces. DO NOT export test double implementations as back doors — design APIs testable via the real implementation's public API. Interfaces are justified ONLY when: there are multiple implementations, you need to decouple packages (break cycles), or a concrete type has a huge API surface but only a few methods are needed.
- **Ownership and visibility:** interfaces belong in the package that *uses* them, not the package that *implements* them. The consumer defines only the methods it uses. DO NOT export interface types unless necessary. The producer MAY export the interface only when: the interface *is* the product (a common protocol like `io.Writer`/`hash.Hash`), to prevent interface bloat across many packages, or to resolve a circular dependency.
- **Designing effective interfaces:** keep them small; document thoroughly (contract, edge cases, expected errors); **accept interfaces, return concrete types**.
- Return an interface (instead of a concrete type) ONLY when: encapsulating to limit the API surface (e.g., `error`, a `ThrottledReader` returned as `io.Reader`); using command/factory/chaining/strategy patterns that select among concrete types at runtime; or breaking a circular dependency. DO NOT return an interface for encapsulation alone without a concrete reason.
- Use type assertions `v.(T)` (with the "comma ok" form `v, ok := x.(T)` for safety) to extract concrete types or convert to another interface. Use type switches (`switch t := x.(type)`) for multi-type dispatch.
- To guarantee at compile time that a type satisfies an interface when no static conversion already does, use a compile-time assertion: `var _ json.Marshaler = (*RawMessage)(nil)`.

### DO NOT

- DO NOT create an interface before a second concrete implementation exists or a concrete need (cycle-breaking, mocking at a real boundary) demands one.
- DO NOT wrap every service, repository, or client in an interface "for testability." Test through the real implementation's public API or use a test double of the underlying dependency (database, HTTP server).
- DO NOT add a layer of indirection (wrapper functions, adapter types) when the underlying API is already sufficient.

## 13. Embedding

- Use interface embedding to form a union of method sets (`io.ReadWriter` embeds `Reader` and `Writer`).
- Struct embedding promotes the embedded type's methods to the outer type. The receiver of a promoted method is the embedded (inner) value, not the outer struct.
- A field/method at a shallower depth hides a same-named item deeper in the type. A duplicate name at the same depth is an error only if the name is actually referenced.
- DO NOT use embedding as a substitute for explicit delegation when the promoted API surface is not appropriate.

## 14. Generics

- Use generics ONLY when they fulfill a business requirement. If existing features (slices, maps, interfaces) solve the problem without generics, use them instead.
- DO NOT use generics just because an algorithm/data structure is type-agnostic. If only one type is instantiated in practice, write code for that specific type.
- DO NOT use generics to invent DSLs or error-handling/assertion frameworks. Use established error handling and testing practices.
- If several types share a useful unifying interface, model the solution with that interface instead of generics. If you would otherwise rely on `any` and type switching, use generics instead.
- For exported APIs using generics, document them and include motivating runnable examples.

### DO NOT

- DO NOT reach for generics when a concrete type or interface suffices.
- DO NOT build generic utility functions (`Map`, `Filter`, `Reduce` over `any`) as a standard library replacement.
- DO NOT use `any` as a type parameter constraint when a narrower constraint exists.

## 15. Type Aliases

- DO NOT use type aliases (`type T1 = T2`) unless migrating packages to new source locations. Use a type definition (`type T1 T2`) to define a new type.

## 16. Concurrency

- DO NOT communicate by sharing memory; share memory by communicating. Pass shared values on channels rather than sharing them across goroutines.
- DO NOT start a goroutine without knowing how it will stop. Bound goroutine lifetimes with `context.Context` and `sync.WaitGroup`.
- Keep concurrent code simple enough that goroutine lifetimes are obvious. If not feasible, document when and why goroutines exit.
- Create channels with `make`; an optional capacity sets the buffer size (default 0 = unbuffered).
- To limit concurrency, use a fixed number of worker goroutines reading from a request channel. DO NOT create unbounded goroutines.
- Use `select` with a `default` clause for non-blocking send/receive.

### DO NOT

- DO NOT start a goroutine without a clear mechanism for stopping it (`context.Context`, done channel, `sync.WaitGroup`).
- DO NOT use `sync.Mutex` to protect shared state when a channel-based design would be simpler.
- DO NOT create unbounded goroutines (one per request without limit). Use worker pools or `semaphore` patterns.

## 17. Error Handling

- Return errors as an extra return value (conventionally the last one) of type `error`. DO NOT ignore error returns (DO NOT discard with `_`). If a function returns an error, check it; handle it, return it, or, in truly exceptional cases, `log.Fatal`/`panic`. In the rare case an error is safely ignorable (e.g., `(*bytes.Buffer).Write` documented to never fail), add a comment explaining why.
- Exported functions that return errors MUST return the `error` interface type, not a concrete error type. Returning `nil` error signals success.
- Provide detailed, structured error types when context helps (e.g., `*os.PathError` with `Op`, `Path`, `Err`).
- Error strings MUST NOT be capitalized (unless beginning with an exported name, proper noun, or acronym) and MUST NOT end with punctuation. (Full displayed messages — logging, test failures — MUST be capitalized.)
- Error strings MUST identify their origin by prefixing with the package or operation name (`"image: unknown format"`).
- Callers MUST use type assertions, type switches, or `errors.Is`/`errors.As` to inspect specific errors. Tests MUST check semantic information, not display strings. DO NOT string-compare error messages unless checking a property like inclusion of a parameter name.

### Error structure and wrapping

- If callers need to interrogate an error, give it structure (sentinel values, custom error types with fields) so it can be inspected programmatically — never by string matching. Document significant sentinel values/error types and whether they are pointer receivers.
- When adding information to errors, avoid redundant context the underlying error already provides. DO NOT add an annotation whose sole purpose is to indicate failure ("failed: %v" — just return `err`); add *new, non-redundant* meaning.
- **`%v` vs `%w`** in `fmt.Errorf`:
  - Use `%v` for simple annotation, for logging/display, or to create a fresh independent error that hides the original's specifics (useful at system boundaries like RPC/IPC/storage where you translate to a canonical error space).
  - Use `%w` to wrap an error so callers can inspect the chain with `errors.Is`/`errors.As`. Use it when adding context while preserving the original for programmatic inspection, and when you document/test the underlying errors you expose.
- **Placement of `%w`**: place `%w` at the end (`[...]: %w`) so the printed text mirrors the error chain (newest-to-oldest). Exception: when wrapping a sentinel error that categorizes the failure, place `%w` at the beginning so the category is immediately visible (`%w: details`).

### Logging errors

- If you return an error, DO NOT log it yourself — let the caller handle it. The caller can log, rate-limit, recover, or stop the program.
- Log messages MUST clearly express what went wrong and include relevant diagnostic info. DO NOT log PII. Use error-level logging ONLY for actionable issues; error-level messages MUST require human action, not just be "more serious" than warnings.
- Use verbose logging with a documented level convention (e.g., debug for small extra info, trace for execution flow, dump for large state). Guard expensive calls so they only run when that verbosity is enabled. With stdlib `log/slog`, arguments are evaluated eagerly, so gate expensive values explicitly:
  ```go
  if logger.Enabled(ctx, slog.LevelDebug) {
      logger.DebugContext(ctx, "Handling", "plan", sql.Explain())
  }
  ```

### Panics

- DO NOT use `panic` for normal error handling. Return `error`. In `package main` and init code, use `log.Fatal` (or `log.Fatalf`) with an actionable message for unrecoverable configuration errors.
- For "impossible" conditions (bugs caught in review/testing), return an error or `log.Fatal`.
- For invariant checks where internal state has become unrecoverable, use `log.Fatal`; `panic` is not reliable (deferred functions MAY deadlock or corrupt state). DO NOT recover panics to avoid crashes — propagating corrupted state causes worse, harder-to-diagnose failures.
- Acceptable panic uses: API misuse (as `reflect` does); internal implementation detail of a package with a matching `recover` at the public API boundary that translates panics to errors and re-panics anything outside its domain; and marking unreachable code after a non-returning function like `log.Fatal`. **Panics MUST never escape across package boundaries.**
- `Must`-style helpers (`MustXYZ`) panic on failure and are appropriate ONLY for setup at program/package initialization time (e.g., `template.Must`, `regexp.MustCompile` for package-level "constants"), or in test helpers (using `t.Fatal`, marked with `t.Helper`). DO NOT use them where ordinary error handling is possible.

### DO NOT

- DO NOT use `panic` for normal error handling. Return `error`.
- DO NOT both log an error and return it. Return it and let the caller decide.
- DO NOT discard errors with `_` unless the function is documented to never fail, and add a comment explaining why.
- DO NOT compare error values by string content (`err.Error() == "..."`). Use `errors.Is` or `errors.As`.
- DO NOT wrap errors with redundant context (`fmt.Errorf("failed: %w", err)` when `err` already contains the relevant information).

## 18. The Blank Identifier

- Use `_` to discard unwanted return values in multi-assignment (e.g., `_, err := os.Stat(path)`).
- DO NOT discard error returns with `_` except in rare, justified, commented cases.
- Use `_` temporarily for unused imports/variables during development, placing such declarations right after the imports and commenting them as work in progress.
- Import a package solely for side effects with `import _ "pkg"` (e.g., registering handlers in `init`).
- Use `var _ Interface = (*Type)(nil)` to assert interface satisfaction at compile time when no other static conversion does so.

## 19. Flags

- Define flags ONLY in `package main` or equivalent. General-purpose packages MUST be configured via Go APIs (explicit function arguments or struct fields), not by exporting flags as a side effect of import. If a flag is unavoidable, its name MUST clearly indicate the package it configures.
- Flag names use underscores to separate words; the variables holding flag values use standard mixed-caps (e.g., `pollInterval = flag.Duration("poll_interval", ...)`).
- Place global flag variables in their own `var` group, following the imports section. For complex CLIs with subcommands, use whatever subcommand library your project has adopted (e.g., `spf13/cobra` or `google/subcommands`); if using cobra, obtain context via `cmd.Context()`.

## 20. String Concatenation

- If concatenating a few strings: use `+`.
- If building a complex formatted string (many `+` operators): use `fmt.Sprintf`. If the target is an `io.Writer`, use `fmt.Fprintf` directly.
- If building a string piecemeal (e.g., in a loop): use `strings.Builder`.
- If formatting is very complex: use `text/template`/`safehtml/template`.
- Use backticks for constant, multi-line string literals. DO NOT use `"" + "...\n" + ...`.

## 21. Global State

- DO NOT export package-level variables that control behavior for all clients. Allow clients to create and use instance values, and pass dependencies as explicit parameters (constructors, function args, struct fields).
- DO NOT use: top-level variables (exported or not), service-locator patterns defined globally, callback registries, or thick-client singletons for backends/storage.
- Global state is safe ONLY when: it is logically constant; the package's observable behavior is stateless (e.g., a private cache whose hits/misses are indistinguishable to callers); it doesn't bleed outside the process; or there's no expectation of predictable behavior.
- If you MUST provide a simplified default-instance API: (1) also offer instance creation APIs; (2) make the global API a thin proxy to the instance API; (3) restrict the global API to binary targets, not libraries; (4) document and enforce invariants and provide a reset-to-default API for testing.

## 22. Testing

- Use the standard `testing` package; it is the ONLY testing framework to use. DO NOT create assertion libraries or use third-party frameworks — use Go itself plus `cmp`/`fmt`.
- When adding a package, include examples of intended usage: a runnable `Example` function (in the test file, not production source) or a simple test demonstrating a complete call sequence. Runnable examples appear in Godoc.

### Test failures

- Tests MUST fail with helpful messages detailing what caused the failure, what inputs were used, the actual result, and what was expected — readable without reading the test source.
- Failure messages MUST include the function name, e.g., `YourFunc(%v) = %v, want %v`, not just `got %v, want %v`.
- Include function inputs in the message when short; otherwise use a named/described test case and print the description.
- Order is "got" before "want" (use the words "got"/"want", not "actual"/"expected").
- For full struct comparisons, construct the expected value and compare with a deep comparison — DO NOT hand-code field-by-field checks. For multiple return values, compare individually.
- Compare stable, semantically relevant results — DO NOT assert on the exact bytes of `json.Marshal` or other dependency output that MAY change.
- Use `t.Error` over `t.Fatal` so a single run reports all failures. Use `t.Fatal` ONLY when subsequent checks would be meaningless or misleading (e.g., decoding unexpected input).
- Use `cmp.Equal`/`cmp.Diff` (with options like `protocmp.Transform` for protobufs, `cmpopts.EquateErrors` for errors) for complex comparisons. DO NOT use `reflect.DeepEqual` (sensitive to unexported fields). For diffs, include a direction legend (e.g., `(-want +got)`) and print a newline before the diff.

### Test structure

- **Subtests** (`t.Run`): use for table-driven tests. Subtests MUST NOT depend on other cases for success/initial state (they MAY be run individually via `go test -run`). Name subtests to be readable in output and useful for filtering — treat names like identifiers, not prose. DO NOT use spaces or slashes in subtest names; put longer descriptions in a separate field.
- **Table-driven tests**: use when many cases share testing logic. Add a descriptive `name` field to the test struct and print it in failures; DO NOT use the row index to identify failures. If cases need different logic, write separate test functions or separate subtests rather than conditionalizing flow inside one table. DO NOT let row values dictate conditional setup — duplicate the setup for clarity. Use field names in test-case struct literals.
- **Test helpers** perform setup/cleanup; failures in them are environment failures, not code-under-test failures. Pass `*testing.T` and call `t.Helper()` to attribute failures to the caller. DO NOT use `t.Helper` to build assertion libraries. If nothing a helper does can fail, drop `t` from its signature.
- **Test package**: tests MAY be in the same package (`package foo` in `foo_test.go`) to access unexported identifiers, or in a `<pkg>_test` package (e.g., `package fireworks_test`) when integration tests have no obvious home or to avoid circular dependencies. The `_test` suffix is an allowed exception to the no-underscores rule.

### Test design

- **Leave testing to the `Test` function**: the ideal place to fail a test is within the `Test` function itself. For shared validation logic, inline it, unify inputs into a table test, or have the validation function return a value/error (not take `*testing.T`) so the `Test` decides whether to fail. `cmp` and `cmp.Transformer` are good designs because they don't know the test context.
- **Acceptance testing**: to let others validate implementations of your interfaces, provide a `<pkg>test` package with an `Exercise*` function that returns an error describing which invariants broke (fail-fast or aggregate-all-failures). Reserve `t.Fatal` for setup failure. DO NOT use this to bypass the no-assertion-library guidance.
- **Use real transports**: when testing integrations over HTTP/RPC, use a real production client connected to a test double (mock/stub/fake) of the backend server, rather than hand-implementing the client. Use testing libraries provided by the service authors where available.
- **`t.Error` vs `t.Fatal`**: use `t.Fatal` for setup failures (especially in helpers) without which the test cannot continue. In table-driven tests without subtests, use `t.Error` + `continue` for per-entry failures; with `t.Run` subtests, use `t.Fatal` (it ends the current subtest and moves to the next).
- **Don't call `t.Fatal` from separate goroutines**: `t.FailNow`/`t.Fatal`/`t.Fatalf` MUST only be called from the test's goroutine. From other goroutines, use `t.Errorf` and return. (`t.Parallel` does not make `t.Fatal` unsafe.)
- **Keep setup scoped**: call setup helpers explicitly in the tests that need them; DO NOT use `init()` for test data. Use `sync.Once` to amortize expensive setup that applies to only some tests and needs no teardown. Use a custom `TestMain` ONLY when *all* tests need common setup *and* teardown. Ensure test cases are hermetic (reset any global state they modify).

### DO NOT

- DO NOT use `reflect.DeepEqual` for comparisons. Use `cmp.Equal`/`cmp.Diff`.
- DO NOT compare error messages as strings in tests. Use `errors.Is` or check error types/fields.
- DO NOT call `t.Fatal` from a goroutine other than the test goroutine. Use `t.Errorf` and return.
- DO NOT use `init()` to set up test fixtures. Call setup helpers explicitly in the tests that need them.
