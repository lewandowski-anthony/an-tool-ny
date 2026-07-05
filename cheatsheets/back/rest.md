# REST API Cheatsheet

> What REST actually is, the rules that make an API "RESTful", and the practical conventions worth following when you design one. Aimed at everyday API work, not academic purity.

---

## What Is REST?

REST (Representational State Transfer) is an architectural style for building networked APIs, described by Roy Fielding in 2000. It isn't a protocol or a standard — it's a set of constraints that, when followed, tend to produce APIs that are simple, scalable, and easy to evolve.

The core idea: you expose **resources** (things like users, orders, products) identified by **URLs**, and you act on them using the standard **HTTP methods**. The server returns a **representation** of the resource's state, usually as JSON.

Most APIs people call "REST" are really "HTTP APIs that borrow REST conventions" — and that's fine. Full compliance (especially HATEOAS) is rare in practice.

---

## The Core Constraints

REST defines six constraints. An API is only truly RESTful if it respects them:

1. **Client–Server** — separate the UI/client from the data storage/server so they can evolve independently.
2. **Stateless** — each request carries everything the server needs; the server stores no client session between requests.
3. **Cacheable** — responses must say whether they can be cached, so clients/proxies can reuse them.
4. **Uniform Interface** — a consistent, predictable way to address and manipulate resources (this is the heart of REST).
5. **Layered System** — a client can't tell whether it's talking to the origin server or an intermediary (proxy, gateway, load balancer).
6. **Code on Demand** (optional) — the server can send executable code (e.g. JavaScript) to extend the client.

> **Note:** Statelessness is the one people break most often. Storing session state on the server hurts scalability — push it to a token (JWT) or a shared store instead.

---

## Resources & URLs

Model your API around **nouns** (resources), not verbs. The HTTP method already provides the verb.

```
GET    /users              # list users
POST   /users              # create a user
GET    /users/42           # get user 42
PUT    /users/42           # replace user 42
PATCH  /users/42           # partially update user 42
DELETE /users/42           # delete user 42

GET    /users/42/orders    # orders belonging to user 42 (nested resource)
```

Conventions worth following:
* Use **plural nouns** for collections (`/users`, not `/user`).
* Use **lowercase** and hyphens for multi-word paths (`/purchase-orders`).
* Don't put verbs in the path (`/getUser`, `/createUser` are not RESTful).
* Keep nesting shallow — one level is usually enough (`/users/42/orders`, not `/users/42/orders/7/items/3/...`).

---

## HTTP Methods (and their properties)

| Method   | Purpose                     | Safe | Idempotent |
|----------|-----------------------------|------|------------|
| `GET`    | Read a resource             | Yes  | Yes        |
| `POST`   | Create / non-idempotent op  | No   | No         |
| `PUT`    | Replace a resource fully    | No   | Yes        |
| `PATCH`  | Update a resource partially | No   | No*        |
| `DELETE` | Remove a resource           | No   | Yes        |

* **Safe** = doesn't change server state. **Idempotent** = calling it N times has the same effect as calling it once.
* `PUT /users/42` twice leaves the same result; `POST /users` twice creates two users.
* PATCH can be idempotent depending on how you design it, but isn't guaranteed to be.

---

## Status Codes That Matter

Return the code that actually fits — don't answer `200` for everything.

**Success**
* `200 OK` — general success (GET, PATCH, PUT).
* `201 Created` — resource created (POST); include a `Location` header pointing to it.
* `202 Accepted` — request accepted for async processing.
* `204 No Content` — success with no body (common for DELETE).

**Client errors**
* `400 Bad Request` — malformed request / validation failure.
* `401 Unauthorized` — not authenticated (missing/invalid credentials).
* `403 Forbidden` — authenticated but not allowed.
* `404 Not Found` — resource doesn't exist.
* `409 Conflict` — state conflict (e.g. duplicate, version mismatch).
* `422 Unprocessable Entity` — semantically invalid data.
* `429 Too Many Requests` — rate limit hit.

**Server errors**
* `500 Internal Server Error` — unexpected failure.
* `503 Service Unavailable` — temporarily down/overloaded.

> **Tip:** `401` means "I don't know who you are", `403` means "I know who you are, and you can't do that."

---

## Request & Response Design

* Use **JSON** as the default format; set `Content-Type: application/json`.
* Keep field naming consistent — pick `camelCase` or `snake_case` and stick to it.
* Return the created/updated resource in the response body so clients don't need a second call.
* Use a consistent, predictable **error shape**:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is already in use",
    "details": [
      { "field": "email", "issue": "duplicate" }
    ]
  }
}
```

* Don't leak stack traces or internal details in error messages.

---

## Filtering, Sorting, Pagination

Use the **query string** for these — they're not new resources:

```
GET /users?status=active&role=admin        # filtering
GET /users?sort=-createdAt,name            # sorting (- = descending)
GET /users?page=2&pageSize=20              # offset pagination
GET /users?limit=20&cursor=eyJpZCI6NDJ9    # cursor pagination (better at scale)
GET /users?fields=id,name,email            # sparse fieldsets
```

Return pagination metadata (total count, next/prev links or cursor) so clients can navigate.

> **Tip:** Cursor-based pagination scales far better than `page/offset` on large, frequently-changing datasets.

---

## Versioning

APIs change; version them so you don't break existing clients.

* **URL path**: `GET /v1/users` — simplest and most visible (most common in practice).
* **Header**: `Accept: application/vnd.myapi.v1+json` — cleaner URLs, less discoverable.

Pick one, be consistent, and only bump the version for **breaking** changes. Additive changes (new optional fields, new endpoints) shouldn't need a new version.

---

## Security Essentials

* Always serve over **HTTPS**.
* Authenticate with **tokens** (OAuth 2.0 / JWT / API keys), not server-side sessions — keeps things stateless.
* Send credentials in the `Authorization` header, never in the URL.
* Enforce **authorization** on every endpoint (don't rely on the client to hide actions).
* Validate and sanitize all input; never trust the client.
* Apply **rate limiting** and return `429` with a `Retry-After` header when exceeded.
* Configure **CORS** deliberately — don't blanket-allow every origin in production.

---

## Caching

* Use `Cache-Control` (e.g. `max-age`, `no-cache`, `private`) to tell clients/proxies what's cacheable.
* Support **`ETag`** + `If-None-Match` for conditional requests; return `304 Not Modified` to save bandwidth.
* `Last-Modified` + `If-Modified-Since` is a simpler alternative.
* Only cache safe methods (`GET`); never cache sensitive per-user data as `public`.

---

## HATEOAS (the part everyone skips)

HATEOAS (Hypermedia as the Engine of Application State) means responses include **links** telling the client what it can do next, so the client discovers actions instead of hardcoding URLs.

```json
{
  "id": 42,
  "status": "pending",
  "_links": {
    "self":   { "href": "/orders/42" },
    "cancel": { "href": "/orders/42/cancel", "method": "POST" },
    "pay":    { "href": "/orders/42/payment", "method": "POST" }
  }
}
```

It's the constraint that makes an API "fully RESTful", but most teams skip it because it adds complexity for limited practical payoff. Know it exists; adopt it when hypermedia navigation genuinely helps.

---

## Best Practices Checklist

* Model around resources (nouns), let HTTP methods be the verbs.
* Use the right status code for each outcome.
* Keep the API **stateless**; put session data in tokens.
* Be consistent: naming, casing, error shapes, pagination.
* Return created/updated resources in the response.
* Document the API (OpenAPI/Swagger) and keep it in sync.
* Version from day one; only break on major versions.
* Secure everything: HTTPS, auth, input validation, rate limits.
* Support caching and conditional requests where it helps.
* Design for clients: predictable, discoverable, hard to misuse.

---

## Common Mistakes

* Verbs in URLs (`/createUser`) instead of `POST /users`.
* Returning `200 OK` with an error payload inside.
* Leaking internal errors and stack traces to clients.
* Stateful sessions that break horizontal scaling.
* Inconsistent naming/casing across endpoints.
* Deeply nested URLs that are painful to use.
* No pagination on collections that grow without bound.
* Breaking existing clients with changes that should have been a new version.

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
