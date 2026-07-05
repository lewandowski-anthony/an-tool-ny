# Java Best Practices Cheatsheet

> Practical Java tips for writing clean, reliable modern Java (17+), with notes that apply across macOS, Windows, and Linux.

---

## General Principles

* **Favor immutability**: make fields `final`, prefer immutable objects; use `record` for data carriers.
* **Program to interfaces**, not implementations: `List<String> x = new ArrayList<>();`.
* **Keep methods small** and single-purpose; keep classes cohesive.
* **Fail fast** by validating arguments early with `Objects.requireNonNull` or guard clauses.
* **Avoid premature optimization** — measure with a profiler (JFR, async-profiler) first.
* **Prefer composition over inheritance.**

---

## Modern Language Features (17+)

```java
// Records — immutable data carriers
public record Point(int x, int y) {

}

// Sealed hierarchies — controlled polymorphism
public sealed interface Shape permits Circle, Square {

}

// Pattern matching + switch expressions
String describe(Shape s) {
	return switch (s) {
		case Circle c -> "circle r=" + c.radius();
		case Square q -> "square s=" + q.side();
	};
}

// Text blocks
String json = """
		{ "name": "Anthony" }
		""";

// var for local inference (keep it readable)
var users = new HashMap<String, User>();
```

---

## Null Handling

* Return **empty collections**, not `null`, from methods.
* Use `Optional<T>` for *return values that may be absent* — not for fields or parameters.
  ```java
  return repo.findById(id);            // Optional<User>
  user.map(User::name).orElse("guest");
  ```
* Never call `Optional.get()` without checking; prefer `orElse`, `orElseThrow`, `map`, `ifPresent`.
* Annotate with `@Nullable` / `@NonNull` (JSpecify, JetBrains) to document intent.

---

## Collections & Streams

```java
// Prefer factory methods for small immutable collections
List<String> list = List.of("a", "b");
Map<String, Integer> m = Map.of("a", 1, "b", 2);

// Streams — declarative transformations
var names = users.stream()
		.filter(u -> u.age() >= 18)
		.map(User::name)
		.sorted()
		.toList();                       // Java 16+ immutable list

// Grouping
Map<Dept, List<Employee>> byDept =
		employees.stream().collect(groupingBy(Employee::dept));
```

* Don't overuse streams for trivial loops; sometimes a `for` loop is clearer and faster.
* Avoid side effects inside stream operations (keep them pure).
* Choose the right collection: `ArrayList` (random access), `LinkedList` (rarely worth it), `HashMap` (lookup), `EnumMap`/`EnumSet` (enums).

---

## Exceptions

* Use **unchecked exceptions** for programming errors; checked only when the caller can meaningfully recover.
* **Never swallow exceptions** (`catch (Exception e) {}`) — log or rethrow with context.
* Throw specific types; include a helpful message.
* Use **try-with-resources** for anything `AutoCloseable`:
  ```java
  try (var in = Files.newInputStream(path)) { ... }
  ```
* Don't use exceptions for control flow.

---

## Concurrency

* Prefer `java.util.concurrent` over raw `synchronized`/`wait`/`notify`.
* Use `ExecutorService` / `CompletableFuture` instead of manually creating threads.
* Favor immutable shared state; guard mutable state with `AtomicX`, `ConcurrentHashMap`, or locks.
* Java 21+: use **virtual threads** (`Executors.newVirtualThreadPerTaskExecutor()`) for high-concurrency I/O.
* Always shut down executors; make `Thread`s daemon or manage lifecycle explicitly.

---

## Code Quality & Style

* Follow a consistent style (Google Java Format, Spotless) — automate it.
* Name things clearly: methods are verbs, classes/booleans read naturally (`isEmpty`, `hasNext`).
* Prefer `equals`/`hashCode` from records or IDE/Lombok; keep them consistent.
* Avoid magic numbers — use named constants or enums.
* Keep visibility minimal (`private` by default); expose only what's needed.
* Use `StringBuilder` in loops, not `+` string concatenation.

---

## Testing

* Use **JUnit 5** with **AssertJ** for fluent assertions and **Mockito** for mocks.
* One logical assertion per test; name tests as behavior (`shouldReturnEmptyWhenNotFound`).
* Follow **Arrange-Act-Assert**.
* Prefer real objects over mocks when cheap; mock only external boundaries.
* Use `@ParameterizedTest` for data-driven cases; **Testcontainers** for DB/integration tests.

---

## Performance & Memory

* Don't create garbage in hot loops; reuse buffers where sensible.
* Use primitive types/arrays over boxed types in performance-critical code.
* Beware autoboxing in collections (`Map<Integer,...>`).
* Close streams/connections; leaks cause slow degradation.
* Profile before optimizing (JFR, VisualVM, async-profiler).

---

## Build & Tooling

* **Maven** or **Gradle** — pin plugin/dependency versions; use a BOM (e.g. Spring) for alignment.
* Run static analysis: SpotBugs, Error Prone, PMD, Checkstyle.
* Keep dependencies current; scan with OWASP Dependency-Check / Trivy.
* Target a supported LTS (17 or 21). Use `--release` to compile for the right bytecode level.

---

## Common Gotchas

* `==` compares references for objects — use `.equals()` (and beware `Integer` caching for `-128..127`).
* Mutable static state is a bug magnet and a concurrency hazard.
* `float`/`double` are imprecise — use `BigDecimal` for money.
* Catching `Throwable`/`Error` hides serious JVM problems.
* Default `Locale`/`Charset`/timezone differ across OSes — set them explicitly (`StandardCharsets.UTF_8`, `ZoneOffset.UTC`).

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
