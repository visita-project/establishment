# Go Guideline

This guideline consolidates idiomatic Go rules extracted from official Go and Google styleguide references (Effective Go, Code Review Comments, Package Names blog, Google Go Style Decisions, and Google Go Best Practices).

## 1. Imports

- DO NOT rename imports unless there is a name collision. If a collision occurs, rename the most local or project-specific import. If the same package is renamed across files, use the same local name.
- Local names for renamed imports MUST follow package naming rules (lowercase, no underscores/mixedCaps). Generated protocol buffer packages MUST be renamed to remove underscores and use a `pb` suffix (`foopb "path/to/foo_go_proto"`); gRPC stubs use a `grpc` suffix. Use whole, descriptive words over very short names like `xpb`.
- `import _ "pkg"` (side-effect import) MUST only be used in the `main` package of a program, or in tests that require it. DO NOT use blank imports in library packages. (Exception: `embed` with `//go:embed`.)
- `import . "pkg"` MUST NOT be used.

## 2. Commentary and Documentation

- Inline explanatory comments MUST be minimal — add them only to signal-boost non-obvious behavior, not to narrate what the code already says.
- Use `//` line comments by default. Reserve `/* */` block comments for package comments or to disable large regions.

### Signal boosting

- When a conditional looks like a common pattern but isn't (e.g., `err == nil` vs the more common `err != nil`), add a comment to draw attention to the difference (`if err == nil { // if NO error`).

## 3. Naming

- Package names MUST be short, clear, lowercase, with no `under_scores` or `mixedCaps`, and MAY include digits (`k8s`, `oauth2`). Multi-word names stay unbroken and all lowercase (`tabwriter`, not `tabWriter` or `tab_writer`). Use simple nouns (`time`, `list`, `http`).
- Abbreviate only when the abbreviation is universally familiar to programmers (`strconv`, `syscall`, `fmt`). DO NOT abbreviate if it makes the name ambiguous.
- DO NOT steal good names from the user: avoid package names commonly used as variables in client code (`bufio`, not `buf`). Avoid names likely shadowed by common local variables (`usercount` is better than `count`).
- DO NOT create packages named `util`, `common`, `misc`, `helper`, `model`, `shared`, or `base`. If you cannot name a package by what it *is*, the boundary is wrong. Break up generic packages by pulling types/functions with common name elements into focused packages.
- DO NOT reuse names of popular standard packages (`io`, `http`). Packages frequently used together MUST have distinct names.
- DO NOT stutter: exported names MUST NOT repeat the package name or surrounding context. In package `chubby`, name the type `File` (`chubby.File`), not `ChubbyFile`. The HTTP server in `http` is `Server`, not `HTTPServer`. If a package exports one type named after itself, the constructor is `New` (`widget.New`, not `widget.NewWidget`). Omit the types of inputs/outputs, the receiver type, and pointer-ness from function/method names. Disambiguate with extra info only when needed (`WriteTextTo`, `WriteBinaryTo`).
- When a function in package `pkg` returns `pkg.Pkg` (or `*pkg.Pkg`), the function name MUST omit the type name. `New` in package `pkg` returns `pkg.Pkg` (`list.New()` -> `*list.List`). When a function returns `pkg.T` where `T` is not `Pkg`, include `T` for clarity (`time.NewTicker`, `time.ParseDuration`).
- Function naming: if a function returns a value, give it a noun-like name; if a function performs an action, give it a verb-like name. If identical functions differ only by type, include the type at the end (`ParseInt`, `ParseInt64`, `AppendInt`); omit the type for the clear "primary" version (`Marshal`, `MarshalText`).
- DO NOT use long names to compensate for poor naming. If a line is too long, shorten the names rather than adding unnatural line breaks.
- Variable names MUST be short, especially for locals. Name length MUST be proportional to scope size and inversely proportional to number of uses: if file-scope, use multiple words; if single-line scope, one letter suffices. DO NOT drop letters to save typing (`Sandbox`, not `Sbx`). Omit type-like words (`users` not `userSlice`, `userCount` not `numUsers`) unless two forms of a value are in scope (`ageString` vs `age`). Omit words clear from context (in a `UserCount` method, `count` or `c` suffices).
- Single-letter names are useful to minimize repetition when the full word is obvious: `r` for `io.Reader`/`*http.Request`, `w` for `io.Writer`/`http.ResponseWriter`, `i` for indices, `x`/`y` for coordinates.
- Constants MUST use `MixedCaps` like all other names (exported uppercase, unexported lowercase). DO NOT use `MAX_PACKET_SIZE` or `kMaxBufferSize`. Name constants by their role, not their value (`MaxPacketSize`, not `Twelve = 12`); if a constant has no role apart from its value, DO NOT define it.
- DO NOT use a `Get`/`get` prefix for getters unless the underlying concept uses "get" (e.g., HTTP GET). Name the getter `Owner` for a field `owner`; setter MAY be named `SetOwner`. For expensive/remote operations, use a word like `Compute` or `Fetch`.
- One-method interfaces MUST be named by the method plus an `-er` suffix: `Reader`, `Writer`, `Formatter`, `CloseNotifier`.
- DO NOT reuse canonical method names (`Read`, `Write`, `Close`, `Flush`, `String`) unless the method has the same signature and meaning. Conversely, if you implement the same semantics, use the same name and signature (`String`, not `ToString`).
- Initialisms/acronyms MUST have a consistent case: `URL` or `url`, never `Url`. Write `ServeHTTP` not `ServeHttp`, `appID` not `appId`. Use the exact same spelling everywhere in the codebase. Initialisms with lowercase letters in prose (`gRPC`, `DDoS`) appear as in prose when unexported (`gRPC`, `iOS`, `ddos`) and fully cased when exported (`GRPC`, `IOS`, `DDoS`).

### Shadowing

- DO NOT use `:=` in a new scope to create a shadowed variable. To conditionally reassign, use `=` and pre-declare `var cancel func()`.
- DO NOT name variables the same as standard packages except in very small scopes.

## 4. Package Size and Layout

- If client code needs two values of different types to interact, put them in the same package. If related types are tightly coupled in implementation, place them in the same package.
- The package name + exported type name form a meaningful identifier (`bytes.Buffer`, `ring.New`).
- DO NOT create single files with thousands of lines or many tiny files. Files MUST be focused enough that a maintainer knows where to find things.
- DO NOT put all project types in a single `types` or `models` package. Place types in the package that uses them.

## 5. Control Structures

- Keep the normal code path at minimal indentation. Handle errors first and return early:
  ```go
  if err != nil {
      // error handling
      return
  }
  // normal code
  ```
- DO NOT line-break an `if` statement (it causes indentation confusion). Instead, extract boolean operands into local variables.
- DO NOT use `break` without a target label at the end of `switch` clauses — it is redundant. Use a comment to clarify an empty clause.

## 6. Functions

- DO NOT use in-band error values (e.g., `-1`, `nil`, `""`) to signal errors or missing results in exported functions. Return an additional value (an `error`, or a `bool` when no explanation is needed) as the final return.
  Values like `nil`, `""`, `0`, and `-1` are fine only when they are valid results the caller need not handle differently.
- Name result parameters when a function returns several values of the same type, when the meaning isn't clear from context, or when the caller MUST take a particular action on a result (e.g., `cancel func()`).

### Function argument lists

- If number of function parameters grow: split into several simpler functions, use an option struct, or use variadic options.
- **Option struct**: a struct collecting some/all arguments, passed as the last parameter. Use when: all callers need some options, many callers provide many options, or options are shared across functions. Contexts MUST NOT be included in option structs.
- **Variadic options**: exported functions returning closures passed to a `...Option` parameter. Use when: most callers need no options, options are infrequent/numerous, options take arguments or can fail, or third parties MAY define options.

## 7. Contexts

- Always pass `context.Context` explicitly as the first parameter. It also applies to test helpers (`func readTestFile(ctx context.Context, t *testing.T, path string)`). Exceptions where context comes from elsewhere: HTTP handlers (`req.Context()`), streaming RPC (stream's `Context()`), test functions (`(testing.TB).Context()`), and entrypoints (`main`, `init`) which MAY use `context.Background()`.
- DO NOT add a `Context` member to a struct type. Add a `ctx` parameter to each method that needs it instead (exception: matching a required external interface signature). DO NOT create custom `Context` types or use interfaces other than `Context` in signatures.

## 8. Data

- Declare empty slices with `var t []string` (a nil slice). The exception is JSON encoding (`nil` -> `null`, `[]string{}` -> `[]`). DO NOT create APIs that force clients to distinguish nil from non-nil zero-length slices; use `len(s) == 0` to test emptiness, not `s == nil`.
- Use `%v` for default formatting, `%+v` for field names, `%q` for quoted strings (use `%q` over manually quoting with `%s`), `%T` for type. Use `any` instead of `interface{}`.
- To customize default formatting, define a `String() string` method.
- DO NOT use `math/rand`/`math/rand/v2` to generate keys, even throwaway ones. Use `crypto/rand.Reader` for random bytes, `crypto/rand.Text` for text, or encode random bytes with `encoding/hex`/`encoding/base64`.
- Specify channel direction where possible (`<-chan int`, `chan<- int`) to prevent programming errors and convey ownership.

## 9. Variable Declarations

- Use `:=` when initializing a new variable with a non-zero value (`i := 42`, not `var i = 42`).
- Preallocate (`make([]Node, 0, 16)`, `make(map[string]bool, shardSize)`) ONLY when sizes are known from empirical analysis. DO NOT preallocate speculatively.

## 10. Initialization

- Use `iota` for enumerated constants.
- Use `init` ONLY for verification or repair of program state that cannot be expressed as a declaration.

## 11. Methods

- Name the receiver as a short (one or two letter) abbreviation of its type (e.g., `c` or `cl` for `Client`). DO NOT use `me`, `this`, or `self`. Keep the receiver name consistent across all methods of the type. If the receiver is unused, omit the name entirely (DO NOT use an underscore).
- Choosing value vs. pointer receiver:
  - If the receiver is a `map`, `func`, or `chan`: use a value receiver.
  - If the receiver is a `slice` and the method doesn't reslice/reallocate: use a value receiver.
  - If the method MUST mutate the receiver: use a pointer receiver.
  - If the receiver is a struct containing a `sync.Mutex` or similar synchronizing field: use a pointer receiver.
  - If the receiver is a large struct or array: use a pointer receiver.
  - If the receiver is a struct/array with pointer fields that MAY be mutated: use a pointer receiver.
  - If the receiver is a small, naturally value-type struct with no mutable fields/pointers (e.g., `time.Time`), or a basic type: use a value receiver.
  - If none of the above apply: use a pointer receiver.

## 12. Interfaces

- Name one-method interfaces after the method plus `-er` suffix (`io.Writer`).
- Interfaces belong in the package that *uses* them, not the package that *implements* them. The consumer defines only the methods it uses. DO NOT export interface types unless necessary. The producer MAY export the interface only when: the interface *is* the product (a common protocol like `io.Writer`/`hash.Hash`).
- Accept interfaces, return concrete types.
- Return an interface (instead of a concrete type) ONLY when: encapsulating to limit the API surface (e.g., `error`, a `ThrottledReader` returned as `io.Reader`); using command/factory/chaining/strategy patterns or breaking a circular dependency.

## 13. Embedding

- Use interface embedding to form a union of method sets (`io.ReadWriter` embeds `Reader` and `Writer`).
- Embedding MAY be a simple convenience.

## 14. Generics

- Use generics ONLY when they fulfill a business requirement. If existing features (slices, maps, interfaces) solve the problem without generics, use them instead.
- DO NOT use generics just because an algorithm/data structure is type-agnostic.
- DO NOT use generics to invent DSLs or error-handling/assertion frameworks.

## 15. Type Aliases

- DO NOT use type aliases (`type T1 = T2`) unless migrating packages to new source locations.

## 16. Concurrency

- DO NOT start a goroutine without a clear mechanism for stopping it (`context.Context`, done channel, `sync.WaitGroup`).
- DO NOT create unbounded goroutines (one per request without limit). Use worker pools or `semaphore` patterns.

## 17. Error Handling

- DO NOT ignore error returns (DO NOT discard with `_`). If a function returns an error, check it; handle it, return it, or, in truly exceptional cases, `panic`. In the rare case an error is safely ignorable (e.g., `(*bytes.Buffer).Write` documented to never fail), add a comment explaining why.
- Exported functions that return errors MUST return the `error` interface type, not a concrete error type.
- Callers MUST use `errors.Is`/`errors.As` to inspect specific errors. Tests MUST check semantic information, not display strings.

### Error structure and wrapping

- When adding information to errors, avoid redundant context the underlying error already provides.
- Place `%w` at the end (`details: %w`). Exception: when wrapping a sentinel error, place `%w` at the beginning (`%w: details`).
- Error strings MUST NOT be capitalized (unless beginning with an exported name, proper noun, or acronym) and MUST NOT end with punctuation (exceptions are: logging, test failures, UI messages). 

### Panics

- DO NOT use `panic`. Exceptions are API misuse (as `reflect` does) and program state initialization (e.g. `Must` functions).
- `Must`-style helpers (`MustXYZ`) panic on failure and are appropriate ONLY for setup at program/package initialization time (e.g., `template.Must`, `regexp.MustCompile`), or in test helpers (using `t.Fatal`, marked with `t.Helper`).

## 18. String Concatenation

- If concatenating a few strings: use `+`.
- If building a complex formatted string (many `+` operators): use `fmt.Sprintf`. If the target is an `io.Writer`, use `fmt.Fprintf` directly.
- If building a string piecemeal (e.g., in a loop): use `strings.Builder`.
- If formatting is very complex: use `text/template`/`safehtml/template`.
- Use backticks for constant, multi-line string literals.

## 19. Global State

- DO NOT export package-level variables that control behavior for all clients. Allow clients to create and use instance values, and pass dependencies as explicit parameters (constructors, function args, struct fields).
- DO NOT use service-locator patterns defined globally, callback registries, or thick-client singletons for backends/storage.
- Global state is safe ONLY when: it is logically constant; the package's observable behavior is stateless (e.g., a private cache whose hits/misses are indistinguishable to callers); it doesn't bleed outside the process; or there's no expectation of predictable behavior.

## 20. Testing

- DO NOT create assertion libraries or use third-party frameworks — use Go itself plus `cmp`/`fmt`.
- Use `t.Cleanup` in tests for cleanup that runs when the test completes.

### Test double and helper package naming

- Create test helper packages by appending `test` to the original package name (e.g., `creditcardtest`). Mark them `testonly`.
- In tests, prefix double variable names (`mockClient`, not `client`).

### Test failures

- Tests MUST fail with helpful messages detailing what caused the failure, what inputs were used, the actual result, and what was expected.
- Order is "got" before "want" (use the words "got"/"want", not "actual"/"expected").
- For full struct comparisons, construct the expected value and compare with a deep comparison — DO NOT hand-code field-by-field checks. For multiple return values, compare individually.
- Compare stable, semantically relevant results (e.g. DO NOT assert on the exact bytes of `json.Marshal`).
- Use `t.Error` over `t.Fatal` so a single run reports all failures. Use `t.Fatal` ONLY when subsequent checks would be meaningless or misleading (e.g., decoding unexpected input).
- Use `cmp.Equal`/`cmp.Diff` (with options like `protocmp.Transform` for protobufs, `cmpopts.EquateErrors` for errors) for complex comparisons. DO NOT use `reflect.DeepEqual`.
- DO NOT compare error messages as strings in tests. Use `errors.Is` or check error types/fields.

### Test structure

- Use table-driven tests when many cases share testing logic. DO NOT use the row index to identify failures. If cases need different logic, write separate test functions or separate subtests rather than conditionalizing flow inside one table. DO NOT let row values dictate conditional setup — duplicate the setup for clarity. Use field names in test-case struct literals.
- Subtests MUST NOT depend on other cases for success/initial state. Name subtests to be readable in output and useful for filtering — treat names like identifiers, not prose. DO NOT use spaces or slashes in subtest names.
- Write and use test helpers to perform setup/cleanup; failures in them MUST be environment failures, not code-under-test failures. Pass `*testing.T` and call `t.Helper()` to attribute failures to the caller. DO NOT use `t.Helper` to build assertion libraries.
- Place tests in `<pkg>_test` package (e.g., `package fireworks_test`).

### Test design

- The ideal place to fail a test is within the `Test` function itself. For shared validation logic, inline it, unify inputs into a table test, or have the validation function return a value/error (not take `*testing.T`) so the `Test` decides whether to fail.
- When testing integrations over HTTP/RPC, use a real production client connected to a test double (mock/stub/fake) of the backend server, rather than hand-implementing the client. Use testing libraries provided by the service authors where available.
- Use `t.Fatal` for setup failures (especially in helpers) without which the test cannot continue. In table-driven tests without subtests, use `t.Error` + `continue` for per-entry failures; with `t.Run` subtests, use `t.Fatal` (it ends the current subtest and moves to the next).
- `t.FailNow`/`t.Fatal`/`t.Fatalf` MUST only be called from the test's goroutine. From other goroutines, use `t.Errorf` and return.
- DO NOT use `init()` for test data.
- Use a custom `TestMain` when tests need common setup and teardown (e.g. in integration tests).
