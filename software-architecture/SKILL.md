---
name: software-architecture
description: Apply software architecture patterns — Hexagonal (Ports and Adapters), Clean Architecture, Domain-Driven Design, CQRS, Event Sourcing — to any backend project. Language-agnostic. Use when designing new systems, refactoring monoliths, or deciding whether a pattern fits.
---

# Software Architecture

A language-agnostic guide to the major backend architecture patterns and **when to use each one**.

> **Sources cited inline.** All pattern definitions trace back to their originators (Evans 2003, Cockburn 2005, Martin 2012/2017, Fowler 2005, Young 2010). Cross-checked against [Sairyss/domain-driven-hexagon](https://github.com/Sairyss/domain-driven-hexagon) and [ThreeDotsLabs/wild-workouts-go-ddd-example](https://github.com/ThreeDotsLabs/wild-workouts-go-ddd-example).

## How to use this skill

When the user asks for architecture decisions, refactoring help, or pattern application:

1. **Start from the decision guide below**, not from a pattern. Patterns serve problems, not the other way around.
2. **Match pattern complexity to domain complexity.** A CRUD admin panel does not need DDD. An e-commerce checkout might.
3. **Cite the source** when applying a definition. "Per Evans, an aggregate is …" beats hand-wavy assertions.
4. **Refuse to over-engineer.** If the user asks for "DDD + CQRS + Event Sourcing" for a TODO app, push back.

---

## Decision guide — which pattern when

Read top-down. Stop at the first matching row.

| If the project has… | Recommended approach |
|---|---|
| ≤2 entities, no real business rules, mostly CRUD over forms | **Plain layered (controller → service → DB)**. No patterns. |
| Some business rules, single team, single deploy unit | **Layered + Hexagonal core** (extract domain from infrastructure; skip DDD tactical patterns) |
| Multiple sub-domains with their own language and rules | **DDD strategic (bounded contexts) + Hexagonal**. Tactical patterns only inside complex contexts. |
| Heavy read/write asymmetry (e.g. dashboards over high-write OLTP) | Add **CQRS** to the contexts that need it. Not globally. |
| Strong audit/replay/temporal requirements | Consider **Event Sourcing** — but only inside one bounded context, and only if the team has done it before. |
| Multiple teams, multiple deploy units | DDD bounded contexts ≈ service boundaries. **Context maps** become integration contracts. |

**Anti-rules:**
- "We'll add DDD later" — bounded contexts are a *strategic* decision; retrofitting is expensive but possible. Tactical patterns can be introduced incrementally.
- "Let's use Clean Architecture for everything" — Clean Architecture's value is the **dependency rule**, not the four-circle diagram. Apply the rule; ignore the ceremony.
- "CQRS means two databases" — no. CQRS means two *models*. Same DB is fine until proven otherwise (Young, original talk).

---

## Hexagonal Architecture (Ports and Adapters)

> **Source:** Alistair Cockburn, *Hexagonal Architecture*, 2005. [alistair.cockburn.us/hexagonal-architecture](https://alistair.cockburn.us/hexagonal-architecture/)

### Core idea

> "Allow an application to equally be driven by users, programs, automated test or batch scripts, and to be developed and tested in isolation from its eventual run-time devices and databases." — Cockburn

A hexagonal system has:
- A **domain core** (business logic, no I/O, no framework imports)
- **Ports** — interfaces that define how the core interacts with the outside
- **Adapters** — implementations of ports, one per technology (HTTP, CLI, Postgres, Stripe, etc.)

### Driving vs driven

- **Driving (primary, "left") ports** — the application *receives* calls through them. Adapter examples: HTTP controller, CLI command, message-queue consumer.
- **Driven (secondary, "right") ports** — the application *makes* calls through them. Adapter examples: repository, payment gateway client, email sender.

The terms left/right come from Cockburn's original drawing. The hexagon shape is incidental — six sides was an arbitrary choice for the diagram. **Don't argue about hexagons.**

### Minimal example (pseudo)

```
// Driving port — what the outside can ask the app to do
interface PlaceOrder {
    execute(cmd: PlaceOrderCommand): OrderId
}

// Driven port — what the app needs from the outside
interface OrderRepository {
    save(order: Order): void
    findById(id: OrderId): Order | null
}

interface PaymentGateway {
    charge(amount: Money, customer: CustomerId): PaymentResult
}

// Core — depends only on ports, not implementations
class PlaceOrderHandler implements PlaceOrder {
    constructor(
        private orders: OrderRepository,
        private payments: PaymentGateway,
    ) {}
    execute(cmd) { /* business logic, calls ports */ }
}

// Adapters — wire technology into ports
class HttpOrderController { /* drives PlaceOrder */ }
class PostgresOrderRepository implements OrderRepository {}
class StripePaymentGateway implements PaymentGateway {}
```

### When NOT to use

- The "core" has no real logic — it's a thin pass-through to the database. Ports add ceremony with no payoff.
- The team will never swap an adapter and never write isolated tests. The architecture's value is unrealized.

---

## Clean Architecture

> **Source:** Robert C. Martin, *The Clean Architecture* (2012 blog post) and *Clean Architecture* (book, 2017). [blog.cleancoder.com](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

### Layers (inside-out)

1. **Entities** — enterprise-wide business rules. The most stable.
2. **Use Cases** — application-specific business rules. Orchestrate entities.
3. **Interface Adapters** — controllers, presenters, gateways. Translate between use cases and frameworks.
4. **Frameworks & Drivers** — DB, web, devices, external APIs. The most volatile.

### The Dependency Rule

> "Source code dependencies must point only inward, toward higher-level policies." — Martin

Inner layers know nothing about outer layers. The use case layer never imports the web framework; it never imports a specific database driver. Inversion is achieved through interfaces *defined by the inner layer* and *implemented by the outer layer*.

### Relation to Hexagonal

Clean Architecture is largely a **synthesis** of Hexagonal (Cockburn) + Onion (Palermo, 2008) + DDD layering. The layers and the dependency rule are essentially the hexagonal idea expressed as concentric circles. **If you've applied hexagonal correctly, you're already mostly Clean.**

### Common misuse

- Treating the **four circles as four mandatory directories**. The number of layers is not sacred; the dependency rule is.
- Adding a **DTO at every layer boundary**. Often the entity itself can cross the inner boundary; only outer-most adapters need DTOs (HTTP request bodies, DB rows).
- **Use case = one class per HTTP endpoint**. Use cases are *application operations*, which sometimes correspond 1:1 to endpoints and sometimes don't.

---

## Domain-Driven Design — Strategic patterns

> **Source:** Eric Evans, *Domain-Driven Design: Tackling Complexity in the Heart of Software*, 2003. The free *DDD Reference* (Evans) summarizes the patterns: [domainlanguage.com/ddd/reference](https://www.domainlanguage.com/ddd/reference/)

### Bounded Context

A boundary within which a particular **domain model** is defined and consistent. Outside the boundary, the same word may mean something different.

> "A model is meaningful only in a context." — Evans

Example: in an e-commerce system, `Customer` in the *Sales* context (with credit limit, sales history) is not the same model as `Customer` in the *Shipping* context (with addresses, delivery preferences). Two contexts, two models, possibly two services.

**Practical rule:** if two parts of the codebase use the same word but the team keeps adding "is it the X kind of Y or the Z kind?" — that's two bounded contexts.

### Ubiquitous Language

The team-wide language used between developers and domain experts, **the same language that appears in code**. If the domain expert says "fulfillment", the class is `Fulfillment`, not `OrderProcessing`.

### Context Map

Documents how bounded contexts relate. Standard relationship types (Evans):
- **Shared Kernel** — small shared model both teams maintain together
- **Customer/Supplier** — upstream context serves downstream
- **Conformist** — downstream accepts upstream's model as-is
- **Anti-Corruption Layer (ACL)** — downstream translates upstream's model into its own (used when upstream is legacy/external)
- **Open Host Service / Published Language** — upstream offers a stable protocol for many consumers
- **Separate Ways** — no integration

The ACL is the most important one in practice. **Always use an ACL when integrating with a legacy or external system you don't control.**

### When NOT to use strategic DDD

- Single bounded context (small project, one team, one model). Strategic patterns are about *managing multiplicity*. With one context, there's nothing to manage.

---

## Domain-Driven Design — Tactical patterns

> **Source:** Evans 2003 + Vaughn Vernon, *Implementing Domain-Driven Design*, 2013, for refinements.

Use these *inside* a bounded context, only when the domain is complex enough to justify them.

### Entity

An object with **identity that persists over time**, distinguishable even when its attributes change. Two `Customer` instances with the same data are not equal — only same-ID is equal.

```
class Customer {
    readonly id: CustomerId  // identity
    name: string             // attributes can change
    email: Email
    equals(other: Customer): boolean { return this.id.equals(other.id) }
}
```

### Value Object

An object **without identity**, defined entirely by its attributes. Two value objects with the same attributes are equal. **Immutable** by convention.

```
class Money {
    constructor(readonly amount: number, readonly currency: string) {}
    add(other: Money): Money { /* returns new Money, never mutates */ }
}
```

Common mistake: making everything a value object, including things with lifecycle (orders, users). Identity is what makes something an entity. If you ever need to track "the same X over time", it's an entity.

### Aggregate and Aggregate Root

A **cluster of entities and value objects** treated as a single consistency unit. One entity is the **root**; external code can only reference the root, not internal members.

> "An aggregate is a cluster of associated objects that we treat as a unit for the purpose of data changes." — Evans

Example: `Order` (root) contains `OrderLine` entities. External code never holds a reference to an `OrderLine`. To modify a line, call methods on `Order`.

**Aggregate sizing rules** (Vernon):
- Prefer **small aggregates**.
- Reference other aggregates **by ID**, not by direct object reference.
- One transaction = one aggregate write. (Multi-aggregate consistency is *eventual*, achieved through events.)

### Repository

A collection-like abstraction for retrieving and persisting aggregates. **One repository per aggregate root**, not per entity.

```
interface OrderRepository {
    save(order: Order): void
    findById(id: OrderId): Order | null
    // Note: NO findOrderLineById — order lines are accessed through Order
}
```

The repository interface lives in the domain; implementations live in adapters (cf. Hexagonal driven ports).

### Domain Service

Behavior that doesn't naturally belong to one entity or value object. Example: a `PricingService` that computes a price using multiple aggregates and policy rules. **Stateless.**

Don't reach for domain services first — check if the behavior fits an entity. Anemic domains often result from over-using services.

### Domain Event

A record that **something significant happened in the domain**. Past-tense names: `OrderPlaced`, `PaymentReceived`, `CustomerDeactivated`.

```
class OrderPlaced {
    constructor(readonly orderId: OrderId, readonly placedAt: Date) {}
}
```

Events are the standard way to:
- Achieve **eventual consistency** between aggregates ("when order is placed, decrement inventory")
- Communicate between **bounded contexts** (with translation through an ACL)
- Build **read models** (CQRS) and **audit logs** (event sourcing)

---

## CQRS — Command Query Responsibility Segregation

> **Source:** Greg Young, ~2010. Foundational article: [martinfowler.com/bliki/CQRS.html](https://martinfowler.com/bliki/CQRS.html) (Fowler summarizing Young).

### Core idea

Use **separate models** for write (commands) and read (queries). The write model enforces invariants; the read model is shaped for query performance.

```
// Write side
class PlaceOrderCommand { /* fields */ }
class PlaceOrderHandler { handle(cmd: PlaceOrderCommand): void }

// Read side
class OrderListQuery { customerId: string }
class OrderListReadModel { /* denormalized fields tuned for the UI */ }
class OrderListHandler { handle(q: OrderListQuery): OrderListReadModel[] }
```

### Common myths

- **"CQRS requires two databases"** — false. Same DB, different tables/views/projections is fine.
- **"CQRS requires Event Sourcing"** — false. They're often combined but independent. (Young is explicit about this.)
- **"CQRS = read replicas"** — that's database scaling, not CQRS. CQRS is about *model* separation, not infrastructure.

### When to use

- Read patterns differ structurally from the write model (e.g. write is normalized aggregates, read is a flat dashboard).
- Write throughput and read throughput diverge enough that one model can't optimize for both.
- You want write-side rules to be strict and read-side queries to be flexible.

### When NOT to use

- The read shape is essentially the write shape. CQRS becomes pure overhead.
- You don't have a complex domain. Plain repository methods are sufficient.

---

## Event Sourcing

> **Source:** Martin Fowler, *Event Sourcing*, 2005. [martinfowler.com/eaaDev/EventSourcing.html](https://martinfowler.com/eaaDev/EventSourcing.html)

### Core idea

Persist **the sequence of events** that led to current state, instead of (or alongside) the current state itself. State is derived by replaying events.

```
// Instead of: UPDATE orders SET status='paid' WHERE id=...
// You append: OrderPaid { orderId, paidAt, amount } to the order's event stream
// Order's current state is computed by folding the event sequence
```

### Benefits

- Complete audit log by construction
- Time travel — reconstruct any past state
- Replay events into new read models (great fit with CQRS)

### Costs (do not underestimate)

- **Schema evolution is hard.** Old events are immutable; you must support old shapes forever or version them.
- **Snapshotting** is needed for long event streams.
- **Eventual consistency** of read models complicates UX.
- **Tooling** (debugging, querying current state, fixing bad events) is non-trivial.

### When to use

- Audit/regulatory requirements demand a non-repudiable history.
- The business actually thinks in events ("we received the payment, then we shipped").
- Team has done it before, or has time to learn the operational pitfalls.

### When NOT to use

- "It would be cool to have." That's not a reason. Event sourcing pays back over years; the cost is upfront.

---

## Anti-patterns

- **Anemic Domain Model** (Fowler) — entities are bags of getters/setters, all behavior is in services. Defeats the point of an object-oriented domain.
- **Smart UI** — business logic in controllers/views. Fast to write, expensive to maintain.
- **Repository leakage** — exposing ORM entities or query builders past the repository boundary.
- **God aggregate** — one aggregate that spans the whole domain. Almost always wrong; split by invariants.
- **DTO explosion** — a separate DTO at every layer boundary. Sometimes one shared shape is fine; only translate where the contract differs.
- **Generic repository over everything** — `Repository<T>` with `find/save/delete` for any aggregate hides intent. Prefer named methods (`findActiveBy(...)`) that express domain queries.
- **Bounded contexts as folders** — a folder named `customer-context` doesn't enforce a context boundary. The boundary is enforced by **separate models, separate persistence, and an integration contract**.
- **Pattern cargo-culting** — copying a sample project's structure without the underlying domain complexity. Patterns should *follow* a need; don't lead with them.

---

## Reference implementations

When demonstrating a pattern in code, point users to working examples rather than fabricating one:

- **DDD + Hexagonal in TypeScript/NestJS** — [Sairyss/domain-driven-hexagon](https://github.com/Sairyss/domain-driven-hexagon) (14.6k★), README doubles as a comprehensive guide
- **DDD + Clean in Go** — [ThreeDotsLabs/wild-workouts-go-ddd-example](https://github.com/ThreeDotsLabs/wild-workouts-go-ddd-example) — refactoring-driven, with explanatory blog series
- **Clean Architecture in Java** — [mattia-battiston/clean-architecture-example](https://github.com/mattia-battiston/clean-architecture-example) (referenced by Uncle Bob's community)

---

## What this skill does NOT cover

- **Specific frameworks** (Spring, NestJS, Django, Rails, etc.) — pattern translations are language/framework dependent; refer to that ecosystem's docs.
- **Microservice deployment topology** — service mesh, k8s, distributed tracing, etc.
- **Database schema design and ORM choices** — orthogonal concerns.
- **Frontend architecture** — these patterns are backend-focused. Some translate (Hexagonal in frontend testing), but that needs its own skill.
- **Detailed event-sourcing operations** — snapshot strategies, projection rebuilds, schema versioning. Use a dedicated ES skill or library docs.
- **Fashion patterns** — anything labeled "the new DDD", "DDD lite", "Clean Architecture v2" without a primary source. If it's not from Evans/Vernon/Cockburn/Martin/Fowler/Young or a peer-reviewed equivalent, treat as opinion.

---

## Verification rules (anti-hallucination)

- **Don't invent definitions.** Every term in this skill (aggregate, value object, ACL, etc.) has a precise definition in Evans/Vernon/Cockburn/Martin/Fowler/Young. If the user asks "what is X exactly", quote or paraphrase the original — do not improvise.
- **Don't conflate patterns.** Hexagonal ≠ Clean ≠ Onion. They overlap but were authored separately. CQRS ≠ Event Sourcing. DDD ≠ microservices.
- **When unsure, refer to:**
  - [DDD Reference (Evans, free PDF)](https://www.domainlanguage.com/ddd/reference/)
  - [Hexagonal Architecture (Cockburn original)](https://alistair.cockburn.us/hexagonal-architecture/)
  - [Clean Architecture (Uncle Bob, blog)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
  - [Martin Fowler's bliki](https://martinfowler.com/bliki/) for CQRS, Event Sourcing, Anemic Domain Model entries
- **Bias toward simplicity.** When the user asks "should I use X?", the default answer is *probably no, unless…*. Patterns are insurance against complexity. Insurance has a premium. If there's no complexity to insure against, you're paying for nothing.
- **The skill is guidance, not law.** If the user has a concrete reason to deviate (team experience, existing constraints, performance), follow them.
