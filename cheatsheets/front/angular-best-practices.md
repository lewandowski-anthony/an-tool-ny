# 🅰️ Angular Best Practices Cheatsheet

> A concise collection of modern Angular (v17+, standalone components + signals) best practices, idioms, and gotchas. Assumes TypeScript throughout.

---

## 🧱 Components & Structure

* Use **standalone components** (no NgModules) in new code — simpler, tree-shakeable.
* Keep components **small and presentational**; push logic into **services**.
* Use **`OnPush` change detection** by default for performance:
  ```ts
  @Component({ changeDetection: ChangeDetectionStrategy.OnPush, ... })
  ```
* One component per file; follow the **Angular Style Guide** naming (`feature.component.ts`, `PascalCase` classes, `kebab-case` selectors with a prefix e.g. `app-`).
* Prefer **smart (container) vs. dumb (presentational)** component separation.

---

## ⚡ Signals (v17+)

* Prefer **signals** for reactive local state over manual `BehaviorSubject` where it fits.
```ts
count = signal(0);
double = computed(() => this.count() * 2);
increment() { this.count.update(n => n + 1); }

effect(() => console.log('count is', this.count()));  // side effects
```
* Use `input()` / `output()` signal APIs and `model()` for two-way binding in modern Angular.
* Signals integrate with `OnPush` cleanly and reduce reliance on `async` pipe boilerplate.

---

## 💉 Dependency Injection

* Inject via the **`inject()`** function or constructor; prefer `inject()` in modern code.
  ```ts
  private http = inject(HttpClient);
  ```
* Provide services at the right scope: `providedIn: 'root'` for singletons, component-level for scoped instances.
* Depend on **abstractions** (interfaces/tokens) for testability; use `InjectionToken` for config.

---

## 🔄 RxJS Discipline

* **Unsubscribe** to avoid memory leaks:
  * Prefer the **`async` pipe** in templates (auto-unsubscribes).
  * Or use `takeUntilDestroyed()` (v16+) in components.
  ```ts
  this.data$ = this.service.load().pipe(takeUntilDestroyed(this.destroyRef));
  ```
* Compose streams with operators (`map`, `switchMap`, `combineLatest`); avoid nested subscriptions.
* Use `switchMap` for cancellable requests (typeahead), `concatMap` for ordered, `mergeMap` for parallel.
* Don't subscribe inside `subscribe` — flatten with the right operator.

---

## 🌐 HTTP & Data

* Centralize API calls in **services**, not components.
* Use **typed responses**: `http.get<User[]>(url)`.
* Use **interceptors** for auth tokens, error handling, and logging.
* Handle errors with `catchError`; surface user-friendly messages.
* Cache/share with `shareReplay` where appropriate.

---

## 🧭 Routing

* Use **lazy-loaded routes** with `loadComponent`/`loadChildren` for code-splitting.
* Protect routes with **functional guards** (`CanActivateFn`).
* Use **resolvers** for prefetching critical data.
* Keep route config declarative and typed.

---

## 📝 Forms

* Prefer **Reactive Forms** (`FormGroup`/`FormControl`) over template-driven for anything non-trivial.
* Type your forms with **typed reactive forms** (v14+).
* Centralize validation logic; create reusable custom validators.
* Show validation feedback based on `touched`/`dirty` state.

---

## 🎨 Templates

* Use the **new control flow** (`@if`, `@for`, `@switch`) over `*ngIf`/`*ngFor` (v17+):
  ```html
  @for (item of items(); track item.id) {
    <li>{{ item.name }}</li>
  } @empty {
    <li>No items</li>
  }
  ```
* **Always provide `track`** in `@for` (or `trackBy` with `*ngFor`) for performance.
* Avoid function calls / heavy expressions in templates — they run on every change detection.
* Use the `async` pipe instead of manual subscription + property.

---

## 🧪 Testing

* Unit test with **Jasmine/Karma** or migrate to **Jest**; use `TestBed` for DI.
* Test services in isolation; mock `HttpClient` with `HttpTestingController`.
* Use **Angular Testing Library** for user-centric component tests.
* E2E with **Cypress** or **Playwright** (Protractor is deprecated).

---

## ⚡ Performance

* `OnPush` + signals/immutability minimize change detection cycles.
* Lazy-load routes and defer non-critical content (`@defer` block, v17+).
* Use `trackBy`/`track` on all lists.
* Avoid heavy work in lifecycle hooks that run often; keep `ngDoCheck` cheap.
* Analyze bundle size (`ng build --stats-json` + analyzer); enable production builds.

---

## ⚠️ Common Gotchas

* **Memory leaks** from un-unsubscribed observables — use `async` pipe / `takeUntilDestroyed`.
* Function calls in templates re-run every CD cycle → cache or use pipes/signals.
* Mutating arrays/objects with `OnPush` → view won't update; replace references.
* `ExpressionChangedAfterItHasBeenCheckedError`: don't change bound values in the wrong lifecycle hook.
* Missing `trackBy`/`track` → full list re-render and lost DOM state.
* Overusing `any` — enable `strict` mode in `tsconfig` and type everything.

---

## 🛠️ Tooling

* Use the **Angular CLI** (`ng generate`, `ng build`, `ng test`) — keep it updated with `ng update`.
* Enable **strict mode** and TypeScript `strict` compiler options.
* Lint with **ESLint** (`angular-eslint`) + Prettier.

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
