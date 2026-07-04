# Go Package Design Guidelines

These rules govern package creation, naming, dependency management, and API surface decisions.

## 1. Package Purpose

- A package MUST provide a solution to a **specific problem domain**. If you cannot describe what the package provides in one sentence, the boundary is wrong — split or merge.
- Package names MUST describe **what the package provides**, not what it contains. Good: `http`, `fmt`, `io`. Bad: `util`, `common`, `helpers`, `misc`, `shared`, `base`.
- A package MUST NOT become a dumping ground of disparate concerns. Every exported symbol MUST relate to the package's core purpose. If unrelated code accumulates, extract it into a focused package.
- DO NOT create packages that exist only to hold types, models, or configuration shared across the project. Place types in the package that uses them.

## 2. Package as a Firewall

- Treat each package as a self-contained unit with a strict boundary — not just a folder of related files.
- Two packages MUST NOT cross-import each other. Imports are one-way. If package A and package B need each other, either merge them or introduce a third package to decouple them.

## 3. Exporting and Encapsulation

- Start identifiers with a capital letter ONLY when they form part of the package's public API. Everything else MUST be unexported.
- The exported surface MUST be the minimum required for the package to fulfill its purpose. When in doubt, keep it unexported.
- Use unexported types, functions, and variables as internal implementation details. The package MUST be free to change internals without breaking consumers.

## 4. Usability — Design for the Consumer

- A package MUST be intuitive and simple to use. The consumer (application developer) MUST be able to use the package without reading its internals.
- A package MUST respect its impact on resources and performance. DO NOT allocate unnecessarily, leak goroutines, or ignore cleanup just because Go's runtime is forgiving.
- The external API MUST protect consumers from cascading internal changes. Use interfaces at package boundaries to decouple consumers from concrete implementation details.
- DO NOT force consumers to perform type assertions to concrete types returned by the package.
- DO NOT supply interfaces solely for the purpose of letting consumers mock your types.

## 5. Portability — Minimize Dependencies

- When adding a dependency, evaluate whether the package truly needs it or whether the functionality can be implemented internally or accepted as an interface.
- DO NOT create a single shared package that many other packages depend on (e.g., `common`, `types`, `shared`). If a type is needed in multiple packages, define it in the package closest to its usage or define an interface.
