# Go Testing Guideline

This guideline covers idiomatic Go testing practices extracted from official Go and Google styleguide references.

## General

- DO NOT create assertion libraries or use third-party frameworks — use Go itself plus `cmp`/`fmt`.
- Use `t.Cleanup` in tests for cleanup that runs when the test completes.

## Test Double and Helper Package Naming

- Create test helper packages by appending `test` to the original package name (e.g., `creditcardtest`). Mark them `testonly`.
- In tests, prefix double variable names (`mockClient`, not `client`).

## Test Failures

- Tests MUST fail with helpful messages detailing what caused the failure, what inputs were used, the actual result, and what was expected.
- Order is "got" before "want" (use the words "got"/"want", not "actual"/"expected").
- For full struct comparisons, construct the expected value and compare with a deep comparison — DO NOT hand-code field-by-field checks. For multiple return values, compare individually.
- Compare stable, semantically relevant results (e.g. DO NOT assert on the exact bytes of `json.Marshal`).
- Use `t.Error` over `t.Fatal` so a single run reports all failures. Use `t.Fatal` ONLY when subsequent checks would be meaningless or misleading (e.g., decoding unexpected input).
- Use `cmp.Equal`/`cmp.Diff` (with options like `protocmp.Transform` for protobufs, `cmpopts.EquateErrors` for errors) for complex comparisons. DO NOT use `reflect.DeepEqual`.
- DO NOT compare error messages as strings in tests. Use `errors.Is` or check error types/fields.

## Test Structure

- Use table-driven tests when many cases share testing logic. DO NOT use the row index to identify failures. If cases need different logic, write separate test functions or separate subtests rather than conditionalizing flow inside one table. DO NOT let row values dictate conditional setup — duplicate the setup for clarity. Use field names in test-case struct literals.
- Subtests MUST NOT depend on other cases for success/initial state. Name subtests to be readable in output and useful for filtering — treat names like identifiers, not prose. DO NOT use spaces or slashes in subtest names.
- Write and use test helpers to perform setup/cleanup; failures in them MUST be environment failures, not code-under-test failures. Pass `*testing.T` and call `t.Helper()` to attribute failures to the caller. DO NOT use `t.Helper` to build assertion libraries.
- Place tests in `<pkg>_test` package (e.g., `package fireworks_test`).

## Test Design

- The ideal place to fail a test is within the `Test` function itself. For shared validation logic, inline it, unify inputs into a table test, or have the validation function return a value/error (not take `*testing.T`) so the `Test` decides whether to fail.
- When testing integrations over HTTP/RPC, use a real production client connected to a test double (mock/stub/fake) of the backend server, rather than hand-implementing the client. Use testing libraries provided by the service authors where available.
- Use `t.Fatal` for setup failures (especially in helpers) without which the test cannot continue. In table-driven tests without subtests, use `t.Error` + `continue` for per-entry failures; with `t.Run` subtests, use `t.Fatal` (it ends the current subtest and moves to the next).
- `t.FailNow`/`t.Fatal`/`t.Fatalf` MUST only be called from the test's goroutine. From other goroutines, use `t.Errorf` and return.
- DO NOT use `init()` for test data.
- Use a custom `TestMain` when tests need common setup and teardown (e.g. in integration tests).
