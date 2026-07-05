# Design Patterns Cheatsheet

> A practical guide to classic GoF design patterns and a few modern ones: what each solves, when it helps, and when it gets in the way. Examples use Java/TypeScript-style pseudocode, but the
> ideas apply across languages.

---

## How to Choose

* **Don't force patterns.** They're a shared vocabulary and a set of proven options, not goals by themselves. Use one when you actually feel the problem it solves.
* Prefer the **simplest** thing that works; refactor toward a pattern when duplication or rigidity appears.
* Favor **composition over inheritance** and **program to interfaces**.

---

## Creational Patterns

*These patterns help you create objects without tightly coupling code to concrete classes.*

| Pattern              | Solves                                 | Use when…                                            |
|----------------------|----------------------------------------|------------------------------------------------------|
| **Factory Method**   | Decouple creation from usage           | Subclasses decide which concrete type to instantiate |
| **Abstract Factory** | Create families of related objects     | You need consistent sets (e.g. UI themes)            |
| **Builder**          | Construct complex objects step by step | Many optional params / immutable objects             |
| **Prototype**        | Clone existing objects                 | Object creation is costly; copy is cheaper           |
| **Singleton**        | Exactly one shared instance            | Genuinely global, stateless service (use sparingly)  |

```java
// Builder — great for many optional fields
Pizza p = new Pizza.Builder()
				.size("L").cheese(true).pepperoni(true)
				.build();
```

### Java Examples

**Factory Method** — a method, often overridden by subclasses, decides the concrete type. *Use it when callers shouldn't depend on concrete classes.*
```java
interface Notification { void send(String msg); }
class EmailNotification implements Notification {
    public void send(String msg) { /* send email */ }
}
class SmsNotification implements Notification {
    public void send(String msg) { /* send sms */ }
}

abstract class NotificationCreator {
    abstract Notification create();                 // factory method
    void notifyUser(String msg) { create().send(msg); }
}
class EmailCreator extends NotificationCreator {
    Notification create() { return new EmailNotification(); }
}
```

**Abstract Factory** — creates *families* of related objects that must stay consistent. *Use it when, for example, a UI theme needs a matching button and checkbox.*
```java
interface Button { void render(); }
interface Checkbox { void render(); }

interface GuiFactory {                              // abstract factory
    Button createButton();
    Checkbox createCheckbox();
}
class DarkFactory implements GuiFactory {
    public Button createButton()   { return new DarkButton(); }
    public Checkbox createCheckbox() { return new DarkCheckbox(); }
}
// Client uses only interfaces → swap the whole family in one line.
```

**Builder** — builds an object step by step. *Use it when an object has many optional parameters or must be immutable.*
```java
public record Pizza(String size, boolean cheese, boolean pepperoni) {
    static class Builder {
        private String size = "M";
        private boolean cheese, pepperoni;
        Builder size(String s)      { this.size = s; return this; }
        Builder cheese(boolean c)   { this.cheese = c; return this; }
        Builder pepperoni(boolean p){ this.pepperoni = p; return this; }
        Pizza build() { return new Pizza(size, cheese, pepperoni); }
    }
}
Pizza p = new Pizza.Builder().size("L").cheese(true).build();
```

**Prototype** — clones an existing instance. *Use it when creation is expensive and copying is cheaper.*
```java
public record Config(String env, List<String> flags) {
    public Config copyWith(String newEnv) {
        return new Config(newEnv, new ArrayList<>(flags)); // clone + tweak
    }
}
Config base = new Config("prod", List.of("a", "b"));
Config staging = base.copyWith("staging");
```

**Singleton** — provides exactly one shared instance. *Use it only for a genuinely global, stateless service.*
```java
public enum Registry {                              // enum = thread-safe singleton
    INSTANCE;
    private final Map<String,String> data = new ConcurrentHashMap<>();
    public void put(String k, String v) { data.put(k, v); }
    public String get(String k) { return data.get(k); }
}
Registry.INSTANCE.put("region", "eu");
```

> **Warning:** **Singleton** is often an anti-pattern: it's global mutable state, hurts testability, and hides dependencies. Prefer dependency injection.

---

## Structural Patterns

*These patterns help compose classes and objects into larger structures without making them hard to change.*

| Pattern       | Solves                                     | Use when…                                           |
|---------------|--------------------------------------------|-----------------------------------------------------|
| **Adapter**   | Make incompatible interfaces work together | Wrapping a third-party/legacy API                   |
| **Bridge**    | Decouple abstraction from implementation   | Both vary independently (shape × renderer)          |
| **Composite** | Treat individual & groups uniformly        | Tree structures (files/folders, UI trees)           |
| **Decorator** | Add behavior without subclassing           | Layered, optional responsibilities (I/O streams)    |
| **Facade**    | Simplify a complex subsystem               | Provide a clean entry point over many classes       |
| **Flyweight** | Share common state to save memory          | Huge numbers of similar objects                     |
| **Proxy**     | Control access / add a stand-in            | Lazy loading, caching, access control, remote calls |

```java
// Decorator — wrap to add behavior
Reader r = new BufferedReader(new InputStreamReader(in));
```

### Java Examples

**Adapter** — makes an incompatible interface fit. *Use it when wrapping a third-party or legacy API.*
```java
interface PaymentProcessor { void pay(int cents); }        // what our app wants
class LegacyStripe { void makePayment(double dollars) { /* ... */ } } // what we have

class StripeAdapter implements PaymentProcessor {
    private final LegacyStripe stripe = new LegacyStripe();
    public void pay(int cents) { stripe.makePayment(cents / 100.0); }
}
```

**Bridge** — separates an abstraction from its implementation so both can vary independently. *Use it when, for example, shapes and rendering engines would otherwise explode into N×M classes.*
```java
interface Renderer { void drawCircle(double r); }          // implementation side
abstract class Shape {                                     // abstraction side
    protected final Renderer renderer;
    Shape(Renderer r) { this.renderer = r; }
    abstract void draw();
}
class Circle extends Shape {
    private final double radius;
    Circle(Renderer r, double radius) { super(r); this.radius = radius; }
    void draw() { renderer.drawCircle(radius); }
}
```

**Composite** — treats single items and groups uniformly. *Use it for tree structures such as files, folders, or UI trees.*
```java
interface FileNode { int size(); }
record File(int size) implements FileNode {
    public int size() { return size; }
}
class Directory implements FileNode {
    private final List<FileNode> children = new ArrayList<>();
    void add(FileNode n) { children.add(n); }
    public int size() { return children.stream().mapToInt(FileNode::size).sum(); }
}
```

**Decorator** — adds behavior by wrapping instead of subclassing. *Use it for layered, optional responsibilities.*
```java
interface Coffee { double cost(); }
class Espresso implements Coffee { public double cost() { return 2.0; } }
class MilkDecorator implements Coffee {
    private final Coffee inner;
    MilkDecorator(Coffee c) { this.inner = c; }
    public double cost() { return inner.cost() + 0.5; }
}
Coffee c = new MilkDecorator(new Espresso());   // 2.5
```

**Facade** — provides one simple entry point over a complex subsystem. *Use it to hide orchestration across many classes.*
```java
class VideoConverter {                          // facade
    public File convert(File src, String fmt) {
        var codec = new CodecFactory().extract(src);
        var buffer = new BitrateReader().read(src, codec);
        return new Muxer().mux(buffer, fmt);    // hides all the steps
    }
}
```

**Flyweight** — shares common immutable state to save memory. *Use it with huge numbers of similar objects.*
```java
class TreeTypeFactory {                          // shared "intrinsic" state
    private static final Map<String,TreeType> cache = new HashMap<>();
    static TreeType get(String name, String texture) {
        return cache.computeIfAbsent(name + texture, k -> new TreeType(name, texture));
    }
}
// Thousands of trees reuse a handful of TreeType instances.
```

**Proxy** — provides a stand-in that controls access. *Use it for lazy loading, caching, access control, or remote calls.*
```java
interface Image { void display(); }
class RealImage implements Image {
    RealImage(String file) { /* expensive disk load */ }
    public void display() { /* ... */ }
}
class LazyImageProxy implements Image {
    private final String file;
    private RealImage real;
    LazyImageProxy(String file) { this.file = file; }
    public void display() {
        if (real == null) real = new RealImage(file);   // load on first use
        real.display();
    }
}
```

---

## Behavioral Patterns

*These patterns organize communication and responsibility between objects.*

| Pattern                     | Solves                                  | Use when…                                 |
|-----------------------------|-----------------------------------------|-------------------------------------------|
| **Strategy**                | Swap algorithms at runtime              | Multiple interchangeable behaviors        |
| **Observer**                | Notify dependents of changes            | Event systems, pub/sub, reactive UIs      |
| **Command**                 | Encapsulate a request as an object      | Undo/redo, queues, transactions           |
| **State**                   | Behavior changes with internal state    | State machines (order lifecycle)          |
| **Template Method**         | Fixed skeleton, variable steps          | Shared algorithm, differing details       |
| **Chain of Responsibility** | Pass a request along handlers           | Middleware, filters, validation pipelines |
| **Mediator**                | Centralize complex interactions         | Many objects talking to each other        |
| **Iterator**                | Traverse without exposing internals     | Custom collections                        |
| **Visitor**                 | Add operations without changing classes | Stable class hierarchy, many operations   |
| **Memento**                 | Capture/restore state                   | Snapshots, undo                           |
| **Interpreter**             | Evaluate a grammar/language             | Small DSLs, expression parsing            |

```java
// Strategy — inject the algorithm
interface Discount {

	double apply(double total);
}
checkout.

setDiscount(total ->total *0.9);
```

### Java Examples

**Strategy** — swaps interchangeable algorithms at runtime. *Use it when you have multiple ways to do one thing.*
```java
interface Discount { double apply(double total); }
Discount none    = total -> total;
Discount tenPct  = total -> total * 0.9;

class Checkout {
    private Discount discount = t -> t;
    void setDiscount(Discount d) { this.discount = d; }
    double total(double raw) { return discount.apply(raw); }
}
```

**Observer** — notifies dependents when state changes. *Use it for event systems, pub/sub, or reactive UIs.*
```java
interface Observer { void update(String event); }
class Subject {
    private final List<Observer> observers = new ArrayList<>();
    void subscribe(Observer o) { observers.add(o); }
    void emit(String event) { observers.forEach(o -> o.update(event)); }
}
```

**Command** — encapsulates a request as an object. *Use it for undo/redo, queues, or transactions.*
```java
interface Command { void execute(); void undo(); }
class InsertText implements Command {
    private final StringBuilder doc; private final String text;
    InsertText(StringBuilder doc, String text) { this.doc = doc; this.text = text; }
    public void execute() { doc.append(text); }
    public void undo()    { doc.delete(doc.length() - text.length(), doc.length()); }
}
Deque<Command> history = new ArrayDeque<>();
```

**State** — changes behavior based on internal state. *Use it for state machines such as order or connection lifecycles.*
```java
interface OrderState { OrderState next(); String label(); }
class Pending implements OrderState {
    public OrderState next() { return new Shipped(); }
    public String label() { return "PENDING"; }
}
class Shipped implements OrderState {
    public OrderState next() { return new Delivered(); }
    public String label() { return "SHIPPED"; }
}
```

**Template Method** — keeps a fixed skeleton while allowing individual steps to vary. *Use it when several algorithms share a structure but differ in details.*
```java
abstract class DataImporter {
    public final void run() { open(); parse(); close(); }   // fixed skeleton
    abstract void parse();                                   // subclass fills in
    void open()  { /* shared */ }
    void close() { /* shared */ }
}
class CsvImporter extends DataImporter { void parse() { /* csv */ } }
```

**Chain of Responsibility** — passes a request along a chain of handlers. *Use it for middleware, filters, or validation pipelines.*
```java
abstract class Handler {
    protected Handler next;
    Handler linkWith(Handler n) { this.next = n; return n; }
    abstract boolean handle(Request r);
    boolean passToNext(Request r) { return next == null || next.handle(r); }
}
class AuthHandler extends Handler {
    boolean handle(Request r) { return r.authed() && passToNext(r); }
}
```

**Mediator** — centralizes complex interactions. *Use it when many objects would otherwise reference each other directly.*
```java
interface ChatMediator { void send(String msg, User from); }
class ChatRoom implements ChatMediator {
    private final List<User> users = new ArrayList<>();
    void register(User u) { users.add(u); }
    public void send(String msg, User from) {
        users.stream().filter(u -> u != from).forEach(u -> u.receive(msg));
    }
}
```

**Iterator** — traverses a collection without exposing its internals. *Use it for custom collections.* (Java's `Iterable`/`Iterator` is the built-in form.)
```java
class Range implements Iterable<Integer> {
    private final int end;
    Range(int end) { this.end = end; }
    public Iterator<Integer> iterator() {
        return new Iterator<>() {
            int cur = 0;
            public boolean hasNext() { return cur < end; }
            public Integer next() { return cur++; }
        };
    }
}
for (int i : new Range(3)) { /* 0,1,2 */ }
```

**Visitor** — adds operations without changing the classes. *Use it with a stable hierarchy and many operations.*
```java
interface Node { <R> R accept(Visitor<R> v); }
record NumberNode(int value) implements Node {
    public <R> R accept(Visitor<R> v) { return v.visit(this); }
}
interface Visitor<R> { R visit(NumberNode n); }
Visitor<Integer> evaluator = n -> n.value();
```

**Memento** — captures and restores state. *Use it for snapshots and undo.*
```java
class Editor {
    private String content = "";
    record Memento(String state) {}
    Memento save() { return new Memento(content); }
    void restore(Memento m) { this.content = m.state(); }
    void type(String s) { content += s; }
}
```

**Interpreter** — evaluates a grammar. *Use it for small DSLs or expression parsing.*
```java
interface Expr { int eval(); }
record Num(int v) implements Expr { public int eval() { return v; } }
record Add(Expr l, Expr r) implements Expr {
    public int eval() { return l.eval() + r.eval(); }
}
int result = new Add(new Num(2), new Num(3)).eval();   // 5
```

---

## Common Architectural / Modern Patterns

| Pattern                  | Purpose                                                        |
|--------------------------|----------------------------------------------------------------|
| **Dependency Injection** | Provide dependencies externally → testable, loosely coupled    |
| **Repository**           | Abstract data access behind a collection-like interface        |
| **Unit of Work**         | Group operations into a single transaction                     |
| **DTO**                  | Transfer data across boundaries without exposing domain models |
| **MVC / MVVM / MVP**     | Separate presentation, logic, and data                         |
| **Dependency Inversion** | Depend on abstractions, not concretions (the "D" in SOLID)     |
| **CQRS**                 | Separate read and write models                                 |
| **Event Sourcing**       | Persist state as a sequence of events                          |
| **Circuit Breaker**      | Stop cascading failures to a failing dependency                |
| **Saga**                 | Manage distributed transactions via compensating steps         |

---

## Anti-Patterns to Avoid

* **God Object**: one class that knows/does everything.
* **Singleton abuse**: hidden global state everywhere.
* **Spaghetti code**: no clear structure or flow.
* **Golden Hammer**: forcing one pattern/tool onto every problem.
* **Premature abstraction**: layers of indirection for imagined future needs (YAGNI).
* **Anemic Domain Model**: data classes with all logic in "service" classes (sometimes fine, often a smell).

---

## SOLID (the foundation)

| Letter | Principle             | In one line                                   |
|--------|-----------------------|-----------------------------------------------|
| **S**  | Single Responsibility | A class should have one reason to change.     |
| **O**  | Open/Closed           | Open for extension, closed for modification.  |
| **L**  | Liskov Substitution   | Subtypes must be usable as their base type.   |
| **I**  | Interface Segregation | Prefer small, specific interfaces.            |
| **D**  | Dependency Inversion  | Depend on abstractions, not concrete classes. |

Also keep **DRY** (don't repeat yourself), **KISS** (keep it simple), and **YAGNI** (you aren't gonna need it) in mind.

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
