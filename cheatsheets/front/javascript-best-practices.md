# 🟨 JavaScript Best Practices Cheatsheet

> A concise collection of modern JavaScript (ES2020+) best practices, idioms, and gotchas for writing clean, robust code. Applies to browser and Node.js across all OSes.

---

## 🧱 Variables & Types

* Use **`const`** by default, **`let`** when reassignment is needed, **never `var`**.
* Prefer **strict equality** `===` / `!==` (avoids type coercion surprises).
* Use template literals over string concatenation: `` `Hello ${name}` ``.
* Beware falsy values: `0`, `''`, `null`, `undefined`, `NaN`, `false`.
* Use `Number.isNaN` / `Number.isInteger` instead of the global versions.

```js
const user = { name: "Ana", age: 30 };
const { name, age = 18 } = user;          // destructuring + default
const copy = { ...user, age: 31 };         // spread (shallow) copy
const list = [...arr1, ...arr2];
```

---

## ⚡ Modern Syntax

```js
// Optional chaining + nullish coalescing
const city = user?.address?.city ?? "unknown";

// Arrow functions (lexical this)
const double = (x) => x * 2;

// Default + rest params
function sum(first = 0, ...rest) { ... }

// Logical assignment
config.timeout ??= 3000;
```

* Use `??` (nullish) when `0`/`''` are valid — `||` treats them as falsy.
* Use `Array` methods (`map`, `filter`, `reduce`, `find`, `some`, `every`) over manual loops for transformations.
* Avoid mutating input arrays/objects in these callbacks — keep them pure.

---

## 🔁 Async & Promises

```js
// Prefer async/await over .then() chains
async function load() {
  try {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch (err) {
    console.error("load failed", err);
    throw err;
  }
}

// Run in parallel when independent
const [a, b] = await Promise.all([fetchA(), fetchB()]);
```

* **Always handle rejections** — an unhandled promise rejection can crash Node.
* Don't `await` in a loop when calls are independent → use `Promise.all`.
* Use `Promise.allSettled` when you need every result regardless of failures.
* Avoid the `async` executor anti-pattern inside `new Promise(...)`.

---

## 🧹 Clean Code

* Small, single-purpose functions with descriptive names.
* Avoid deep nesting — return early (guard clauses).
* No magic numbers/strings — extract named constants.
* Prefer pure functions and immutability; minimize side effects.
* Keep modules focused; use named exports for clarity (default exports are harder to refactor).

---

## 🧯 Error Handling

* Throw `Error` objects (or subclasses), never strings.
* Add context to errors; don't swallow them silently.
* Validate inputs at boundaries (API/user input).
* In Node, listen for `unhandledRejection` / `uncaughtException` at the top level for observability.

---

## 🧪 Testing & Tooling

* **ESLint** + **Prettier** — automate linting and formatting (fail CI on lint errors).
* Test with **Vitest** or **Jest**; test behavior, not implementation.
* Use **TypeScript** (or JSDoc types) for anything non-trivial — it catches whole classes of bugs.
* Prefer `npm ci` in CI for reproducible installs; commit the lockfile.

---

## 📦 Modules & Packaging

* Use **ES Modules** (`import`/`export`) over CommonJS in new code.
* Keep dependencies lean; audit with `npm audit` / Trivy.
* Pin versions and use a lockfile; avoid `latest`.
* Tree-shake: prefer named imports so bundlers can drop unused code.

---

## ⚠️ Common Gotchas

* `this` binding: arrow functions capture lexical `this`; regular functions don't.
* Floating point: `0.1 + 0.2 !== 0.3` — round or use integer cents / a decimal lib.
* `typeof null === "object"` (historical bug) — check with `=== null`.
* `[] == false` is `true` (coercion) — always use `===`.
* Reference vs value: objects/arrays are passed by reference; copies are shallow by default (use `structuredClone` for deep).
* `for...in` iterates keys (incl. inherited); use `for...of` for values, `Object.entries` for objects.
* Mutating state in frameworks (React/Vue) breaks change detection — replace, don't mutate.

---

## 🌐 Cross-Platform / Runtime Notes

* Paths differ across OSes — use Node's `path` module, not manual `/` concatenation.
* Line endings: configure `.editorconfig` + Prettier to normalize (CRLF vs LF).
* Environment variables: use `process.env`; load `.env` with `dotenv` (never commit secrets).
* Target the right environment: browser (no `fs`), Node (no `window`), or both (isomorphic).

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
