# React Best Practices Cheatsheet

> Practical React notes for modern apps: function components, hooks, common patterns, and the gotchas worth remembering. These tips apply whether you use Vite, Next.js, or another build setup.

---

## Components

* Use **function components + hooks** exclusively in new code (no class components).
* Keep components **small and focused**; extract logic into custom hooks.
* One component per file; name files and components in `PascalCase`.
* Prefer **composition** (children/props) over prop-drilling deep trees.
* Keep components **pure**: same props → same output, no side effects during render.

```jsx
function UserCard({ user, onSelect }) {
  return (
    <button onClick={() => onSelect(user.id)}>
      {user.name}
    </button>
  );
}
```

---

## Hooks Rules

* **Only call hooks at the top level** — never inside conditions, loops, or nested functions.
* **Only call hooks from React functions** (components or custom hooks).
* Custom hooks start with `use` and encapsulate reusable stateful logic.

```jsx
function useDebounce(value, delay = 300) {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(id);        // cleanup!
  }, [value, delay]);
  return debounced;
}
```

---

## State Management

* **Keep state minimal** — derive values during render instead of storing them.
* **Lift state up** only as far as needed; colocate state near where it's used.
* Use `useState` for local, `useReducer` for complex/related state transitions.
* For shared state: **Context** (low-frequency), or a library (Zustand, Redux Toolkit, Jotai) for larger apps.
* For **server state**, use **TanStack Query (React Query)** or SWR — don't hand-roll caching in `useEffect`.
* **Never mutate state** — always create new objects/arrays:
  ```jsx
  setItems(prev => [...prev, newItem]);
  setUser(prev => ({ ...prev, name }));
  ```

---

## useEffect Discipline

* An Effect is for **synchronizing with external systems** (network, subscriptions, DOM), not for reacting to every render.
* Always specify a correct **dependency array**; don't lie to the linter.
* **Return a cleanup** function for subscriptions/timers/listeners.
* Don't use Effects to transform data for rendering (do it inline) or to handle user events (do it in handlers).
* Fetch data with a library or frameworks' loaders rather than raw Effects when possible.

```jsx
useEffect(() => {
  const controller = new AbortController();
  fetch(url, { signal: controller.signal }).then(...);
  return () => controller.abort();
}, [url]);
```

---

## Performance

* **Lists need stable `key`s** — use IDs, never array indexes (for dynamic lists).
* Memoize expensive computations with `useMemo`; memoize callbacks passed to memoized children with `useCallback`.
* Wrap pure presentational components in `React.memo` when they re-render needlessly.
* Don't over-memoize — it adds complexity; profile with React DevTools first.
* **Code-split** with `React.lazy` + `<Suspense>` for large routes/components.
* React 19 / the React Compiler can auto-memoize — lean on it when available.

---

## JSX & Rendering

* Conditional rendering: `{cond && <X/>}` or ternaries; avoid `0 && <X/>` (renders `0`).
* Keep JSX declarative; extract complex logic above the return.
* Fragments (`<>...</>`) avoid unnecessary wrapper DOM nodes.
* Controlled inputs: bind `value` + `onChange`; keep form state consistent.

---

## Project Structure

* Group by **feature/domain**, not by type (`/features/auth/...` over `/components`, `/hooks` globally).
* Co-locate component, styles, tests, and hooks.
* Keep a clear boundary between **UI components** and **data/logic**.

---

## Testing

* Use **React Testing Library** — test what the user sees/does, not internals.
* Query by role/label/text, not test IDs where possible.
* Mock network with **MSW**; avoid mocking React internals.
* Test custom hooks in isolation.

---

## Common Gotchas

* **Stale closures**: values captured in Effects/callbacks are frozen per render — use functional updates or correct deps.
* **Index as key** causes bugs on reorder/insert/delete.
* Mutating state/props directly → UI won't update.
* Setting state in render → infinite loop.
* Forgetting Effect cleanup → memory leaks and duplicate subscriptions.
* Overusing Context for high-frequency updates → re-renders everything consuming it.
* `useEffect` running twice in dev is **Strict Mode** (intentional) — make effects idempotent.

---

## Tooling

* **Vite** for SPAs, **Next.js** for SSR/SSG/full-stack.
* ESLint with `eslint-plugin-react-hooks` (enforces hook rules) + Prettier.
* TypeScript strongly recommended for props/state safety.

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
