# OpenAPI Specification Best Practices for AI Agents

This document collects practical best practices for generating and reviewing OpenAPI specifications. It is derived from the [Zalando RESTful API and Event Guidelines](https://opensource.zalando.com/restful-api-guidelines/) and adapted for general use by AI agents.

Use this guide as the default standard when implementing, editing, or reviewing OpenAPI specs in this project.

---

## 1. Core Principles

- **API First**: Define the OpenAPI specification before writing implementation code. The spec is the contract between provider and consumers.
- **Resource Orientation**: Model business entities as resources (nouns) identified by URIs and manipulated via standard HTTP methods. Avoid RPC-style action URLs.
- **Consistency**: Prefer common names, shapes, and conventions so APIs look like they were authored by the same team.
- **Backward Compatibility**: Prefer additive, compatible changes. Avoid breaking existing consumers.
- **U.S. English**: All names, descriptions, documentation, and examples must be in U.S. English.

---

## 2. OpenAPI Document Structure

- Use a **single self-contained YAML file** for the API specification.
- Prefer **OpenAPI 3.1** for new specs. OpenAPI 3.0 is acceptable if tooling requires it.
- Keep the spec under version control and publish it alongside the running service.
- Avoid fragile local or remote `$ref` references to content that can change. If remote fragments are used, ensure they are immutable and controlled.

### Required `info` Metadata

Every spec must include:

```yaml
openapi: 3.1.0
info:
  title: Parcel Service API          # unique, descriptive name
  version: 1.3.7                     # semantic version
  description: API for ...           # proper description
  contact:
    name: Team Name
    url: https://...
    email: team@example.com
  x-api-id: d0184f38-b98d-11e7-9c56-68f728c1ba70  # globally unique, immutable
  x-audience: company-internal       # audience classification
```

- `version` must follow semantic versioning (`MAJOR.MINOR.PATCH`). No pre-release or build metadata.
- `x-api-id` should be a UUID and must never be reused across different APIs.
- `x-audience` must be exactly one of:
  - `component-internal`
  - `business-unit-internal`
  - `company-internal`
  - `external-partner`
  - `external-public`

---

## 3. URL and Path Design

### Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Path segments | kebab-case, lowercase | `/shipment-orders` |
| Resource names | plural nouns, domain-specific | `/orders`, `/sales-order-items` |
| Query parameters | snake_case | `sort`, `created_after` |
| Path parameters | kebab-case inside braces | `{shipment-order-id}` |

### Rules

- **Pluralize resource names**: `/orders`, `/customers/{id}/addresses`.
- **Keep URLs verb-free**: use `/orders/{id}/cancellations` with `POST`, not `/orders/{id}/cancel`.
- **Use kebab-case for static path segments**: `/sales-order-items`.
- **Normalize paths**: no trailing slashes, no empty segments, no `//`.
- **Do not prefix paths with `/api`**: deployment base paths belong in `servers`.
- **Identify sub-resources via path segments**: `/resources/{id}/sub-resources/{sub-id}`.
- **Limit nesting**: use at most 3 sub-resource levels.
- **Limit resource types**: well-focused APIs typically expose 4–8 resource types.
- **URL-friendly identifiers**: resource IDs should match `[a-zA-Z0-9:._\-/]*`.
- **Compound keys**: may be exposed as `/resources/{key1}/{key2}`; treat the combined key as opaque in responses.

### Conventional Query Parameters

Use these standard names for common concerns:

- `q` — default keyword/query search
- `sort` — comma-separated sort fields, prefix with `+` (asc) or `-` (desc)
- `fields` — partial field selection
- `embed` — eager-load sub-resources, e.g., `embed=(items)`
- `offset` / `cursor` / `limit` — pagination

### Array Serialization

Explicitly declare how arrays are serialized in headers and query parameters:

- Header comma-separated: `style: simple, explode: false`
- Query comma-separated: `style: form, explode: false`
- Query repeated: `style: form, explode: true`

---

## 4. JSON Payload Design

### Format

- Use **JSON** as the payload format.
- **Top-level response bodies must always be JSON objects**, never arrays or bare values. This allows safe future extension.
- Use UTF-8 encoding and valid Unicode.

### Property Naming

- Property names must be **snake_case**: `customer_number`, `created_at`.
- Array properties should be **plural**: `items`, `order_lines`.
- Object properties should be singular.
- Enum values should be **UPPER_SNAKE_CASE** strings unless mirroring an external standard.

### Schema Design

- Prefer a **single resource schema** for reading and writing. Mark request-only fields as `writeOnly` and response-only fields as `readOnly`.
- Define maps with `additionalProperties`:

  ```yaml
  translations:
    type: object
    additionalProperties:
      type: string
  ```

- Treat schemas as **open for extension by default**. Do **not** set `additionalProperties: false` on API schemas.
- Servers should reject unknown input fields; clients must tolerate unknown response fields.

### Null and Absence

- Use the **same semantics for `null` and absent properties**. Do not assign different meanings to the two states.
- Do not use `null` for boolean properties. If a third state is needed, use a string enum.
- Represent empty arrays as `[]`, not `null`.

### Common Field Names

Reuse standard field names consistently:

- `id` — opaque string identifier
- `{resource}_id` — foreign key reference
- `etag` — embedded sub-resource ETag
- `created_at`, `modified_at` — timestamps

### Date/Time Properties

- Use standard RFC 3339 / ISO 8601 string formats: `date`, `time`, `date-time`, `duration`, `period`, `time-local`, `date-time-local`, `tz-id`.
- Prefer UTC `date-time` values. Use `time-local` / `date-time-local` only for wall-clock times and pair with a separate `tz-id` field.
- Name date/time fields recognizably: include `date`, `time`, `timestamp`, or end with `_at`.

### Numbers and Money

- Always specify a `format` for `number` and `integer` types: `int32`, `int64`, `float`, `double`, `decimal`.
- Money must be an object with:

  ```yaml
  type: object
  properties:
    amount:
      type: number
      format: decimal
    currency:
      type: string
      format: iso-4217
  ```

### Country, Language, Currency

- Country: `iso-3166-alpha-2`
- Language: `iso-639-1` or `bcp47`
- Currency: `iso-4217`

### Identifiers

- Prefer opaque string identifiers over UUIDs unless distributed ID generation is required.
- If using UUIDs, favor UUIDv4 or ULID. Never expose sequential numeric IDs to untrusted clients.

---

## 5. HTTP Methods and Semantics

| Method | Use | Properties |
|--------|-----|------------|
| `GET` | Read resource/collection | Safe, idempotent, no request body |
| `POST` | Create on collection or trigger process | Not required to be idempotent |
| `PUT` | Replace/create entire resource | Idempotent |
| `PATCH` | Partial update | Use `application/merge-patch+json` preferred, or `application/json-patch+json` |
| `DELETE` | Remove resource | Idempotent |
| `HEAD` | Headers only | Same as `GET` |
| `OPTIONS` | Inspect allowed methods | Safe, idempotent |

- For long or structured queries that do not fit in a URL, use `POST` and document it as a `GET with body` equivalent.
- Design `POST` and `PATCH` to be idempotent where feasible using `Idempotency-Key`, conditional headers, or secondary business keys.
- For long-running operations, expose a job resource and return `201 Created` with a `Location` header to poll status.

---

## 6. HTTP Status Codes

- Use only official IANA-registered HTTP status codes.
- Specify **all** success and service-specific error responses. Generic errors (401, 403, 404, 500, 503) may be covered by a `default` response.
- Choose the **most specific** status code available.
- Prefer well-known codes: 200, 201, 202, 204, 207, 304, 400, 401, 403, 404, 405, 406, 409, 410, 412, 415, 423, 428, 429, 500, 501, 502, 503, 504, 507.
- Use `207 Multi-Status` for batch/bulk requests unless the failure applies to the whole request.
- Use `429 Too Many Requests` for rate limits and include `Retry-After` or rate-limit headers.
- Avoid redirection codes (3xx) in APIs; fix URLs at the source or use deprecation instead.

---

## 7. Error Handling

- Every endpoint must be capable of returning **RFC 9457 Problem JSON** (`application/problem+json`) for 4xx and 5xx errors.
- Clients must tolerate missing Problem bodies.
- Never expose stack traces or internal implementation details in error responses.

Example `default` response:

```yaml
responses:
  default:
    description: Error
    content:
      application/problem+json:
        schema:
          $ref: '#/components/schemas/Problem'
```

---

## 8. Security

- Every endpoint must declare authentication/authorization in the OpenAPI spec.
- Prefer the `http` `bearer` security scheme for JWT/bearer tokens:

  ```yaml
  components:
    securitySchemes:
      BearerAuth:
        type: http
        scheme: bearer
        bearerFormat: JWT
  security:
    - BearerAuth: [scope-name]
  ```

- Use `oauth2` flows only when the service truly implements them.
- Assign a permission/scope to every endpoint that requires authorization. If no specific scope is needed, make this explicit.
- Use consistent scope naming such as `{service}.{optional-resource}.{read|write}`.

---

## 9. Headers

- Use standard HTTP headers defined by non-obsolete RFCs.
- Custom headers should use **kebab-case with title-cased separate words**: `If-None-Match`, `Accept-Encoding`.
- Use `Content-*` headers correctly to describe the message body.
- Prefer `Location` over `Content-Location` for created-resource URLs.
- Support conditional requests with `ETag` / `If-Match` / `If-None-Match` for optimistic locking.
- Consider supporting `Idempotency-Key` for safe retries.
- Consider supporting `Prefer` (RFC 7240) for processing preferences such as `respond-async`, `return=minimal`, `return=representation`.
- Support a request correlation ID header (e.g., `X-Request-ID`) on every request and propagate it downstream.
- Avoid proprietary `X-*` headers for business semantics; headers should carry protocol-level context.

---

## 10. Pagination

- All collections that can exceed a few hundred items must support pagination.
- Prefer **cursor-based pagination** over offset-based pagination for large or changing datasets.
- Use standard query parameter names: `offset`, `cursor`, `limit`.
- Return a consistent page object:

  ```yaml
  type: object
  properties:
    items:
      type: array
      items:
        $ref: '#/components/schemas/Order'
    self:
      type: string
      format: uri
    first: { type: string, format: uri }
    prev: { type: string, format: uri }
    next: { type: string, format: uri }
    last: { type: string, format: uri }
  ```

- Provide absolute pagination links.
- Avoid total result counts by default. If required, offer via `Prefer: return=total-count`.

---

## 11. Hypermedia and Links

- Use REST maturity level 2 by default; HATEOAS is optional.
- Links embedded in representations must use at least an `href` property of type `string` with `format: uri`.
- For pagination and `self` links, a plain URI string with the link relation (`self`, `next`, `prev`, `first`, `last`) is sufficient.
- Use full, absolute URIs for hyperlinks.
- Embed links directly in the JSON payload. Do not use RFC 8288 `Link` headers with JSON responses.

---

## 12. Performance

- Support `gzip` compression via `Accept-Encoding` / `Content-Encoding`.
- Support partial responses via the `fields` query parameter.
- Support optional embedding of sub-resources via the `embed` query parameter.
- Document cacheable `GET`, `HEAD`, and `POST` endpoints with `Cache-Control`, `Vary`, and `ETag` headers. Default to `Cache-Control: no-store` when caching is not intended.

---

## 13. Compatibility and Versioning

- Do not break backward compatibility.
- Prefer compatible extensions:
  - Add optional fields; never remove fields.
  - Do not change required/optional status of existing fields.
  - Do not tighten validation constraints on existing fields.
- Reject unknown input fields with `400 Bad Request` unless explicitly documented otherwise.
- Clients must ignore unknown response fields and handle new enum values gracefully.
- For output enums likely to grow, use `examples` rather than closed `enum`, and prefix the description with "Extensible enum."
- Avoid versioning. If unavoidable, use **media type versioning** (content negotiation), never URL versioning.

### Deprecation

- Mark deprecated operations, parameters, schemas, or properties with `deprecated: true`.
- Explain the replacement and migration path in the description.
- During deprecation, return `Deprecation` and `Sunset` headers.
- Do not shut down an API or feature until consumers have migrated or consented to a sunset date.
- New clients must not integrate against deprecated APIs.

---

## 14. Events (if applicable)

- Treat event payloads as part of the service interface; they must follow the same data-format, payload, and compatibility rules as REST API payloads.
- Define event schemas using OpenAPI Schema Objects.
- Use semantic versioning for event schemas.
- Maintain backward compatibility for events; evolution must be additive.
- Avoid wildcard `additionalProperties: true` in event schemas.
- Event type names should be globally unique and readable, e.g., `{service-domain}.{event-name}[.v{major-version}]`.

---

## 15. Quick Checklist

Before finalizing an OpenAPI spec, verify:

- [ ] Single self-contained YAML file using OpenAPI 3.1 (or 3.0 if required).
- [ ] `info` block contains title, semantic version, description, contact, `x-api-id`, and `x-audience`.
- [ ] Paths use kebab-case, plural nouns, no verbs, no trailing slashes, no `/api` prefix.
- [ ] Query parameters use snake_case and conventional names.
- [ ] JSON properties use snake_case; array names are plural.
- [ ] Top-level response bodies are JSON objects.
- [ ] Standard data formats are used for dates, numbers, countries, languages, currency, and UUIDs.
- [ ] HTTP methods follow RFC 9110 semantics.
- [ ] All success and error responses are documented; errors use Problem JSON.
- [ ] Security is declared with bearer/OAuth2 schemes and scopes.
- [ ] Pagination uses cursor-based links where possible; no total count by default.
- [ ] Schemas are open for extension (`additionalProperties` not set to `false`).
- [ ] Versioning is avoided; if needed, media type versioning is used, never URL versioning.
- [ ] Descriptions and examples are in U.S. English.

---

*Source: [Zalando RESTful API and Event Guidelines](https://opensource.zalando.com/restful-api-guidelines/). Adapted and generalized for AI agent use.*
