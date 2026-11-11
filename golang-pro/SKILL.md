---
name: golang-pro
description: Idiomatic, modern Go for any Go project. Two layers — (1) modern syntax/stdlib per Go version (1.0–1.27), (2) idiomatic patterns for errors, interfaces, packages, testing, concurrency, naming. Use when writing or reviewing Go code.
---

# Golang Pro

A two-layer skill for writing idiomatic Go.

- **Layer 1** — modern syntax/stdlib features per Go version (sourced from JetBrains/go-modern-guidelines)
- **Layer 2** — idiomatic patterns the version-table doesn't cover (errors, interfaces, packages, testing, concurrency, naming)

## Target Go Version

Determine the target Go version before applying Layer 1:

1. Prefer the `go` directive from the nearest `go.mod` relevant to the user's task.
2. If multiple modules are involved, use the module being edited or reviewed. If the task spans modules with different versions, use the lowest relevant version unless the user says otherwise.
3. If available, you may run `scripts/detect-go-version.sh [path]` from this skill directory to summarize `go.mod` versions in a workspace.
4. If no version can be determined, ask the user which version to target.

## How to use

Use the target Go version determined above. Do not assume the latest Go version if the project declares an older one.

**If version detected:**
- Briefly tell the user: "Targeting Go X.XX — using language features and stdlib up to that version, plus idiomatic patterns."
- Do NOT enumerate features. Do NOT ask for confirmation.

**If version is still unknown:**
- Ask: "Could not detect Go version. Which to target? [1.24 / 1.25 / 1.26 / 1.27]"

**While writing or reviewing Go code, apply BOTH layers:**
- Layer 1: prefer modern features available at target version; never use newer.
- Layer 2: apply regardless of version.

---

# Layer 1 — Modern syntax/stdlib by version

> Source: [JetBrains/go-modern-guidelines](https://github.com/JetBrains/go-modern-guidelines), MIT-licensed. Synced with upstream commit `155dc7c` (2026-09-10, after v1.1.1; `FEATURES.md`). Update by re-syncing this section against a newer commit and recording it here.

### Go 1.0+
- `time.Since`: `time.Since(start)` instead of `time.Now().Sub(start)`

### Go 1.8+
- `time.Until`: `time.Until(deadline)` instead of `deadline.Sub(time.Now())`

### Go 1.13+
- `errors.Is`: `errors.Is(err, target)` instead of `err == target` (works with wrapped errors)

### Go 1.18+
- `any`: use `any` instead of `interface{}`
- `bytes.Cut` / `strings.Cut`: `before, after, found := strings.Cut(s, sep)` instead of Index+slice
- `strings.Clone`: copy a string so a small substring doesn't keep a large backing array alive (instead of `string([]byte(s))`)

### Go 1.19+
- `fmt.Appendf`: `buf = fmt.Appendf(buf, "x=%d", x)` instead of `[]byte(fmt.Sprintf(...))`
- `atomic.Bool` / `atomic.Int64` / `atomic.Pointer[T]`: type-safe atomics instead of `atomic.StoreInt32`

```go
var flag atomic.Bool
flag.Store(true)
if flag.Load() { ... }

var ptr atomic.Pointer[Config]
ptr.Store(cfg)
```

### Go 1.20+
- `bytes.Clone`: copy a byte slice without sharing memory
- `strings.CutPrefix` / `strings.CutSuffix`: `if rest, ok := strings.CutPrefix(s, "pre:"); ok { ... }`
- `errors.Join`: `errors.Join(err1, err2)` to combine multiple errors
- `context.WithCancelCause`: `ctx, cancel := context.WithCancelCause(parent)` then `cancel(err)`
- `context.Cause`: `context.Cause(ctx)` returns the cause

### Go 1.21+

**Built-ins:**
- `min` / `max`: `max(a, b)` instead of if/else
- `clear`: `clear(m)` to delete all map entries; `clear(s)` to zero slice elements

**slices:**
- `slices.Contains`, `slices.Index`, `slices.IndexFunc`
- `slices.SortFunc(items, func(a, b T) int { return cmp.Compare(a.X, b.X) })` instead of `sort.Slice`. `SortFunc` is **not stable** — replace `sort.SliceStable` with `slices.SortStableFunc`.
- `slices.Sort`, `slices.Max`, `slices.Min`, `slices.Reverse`, `slices.Compact`, `slices.Clip`, `slices.Clone`

**maps:**
- `maps.Clone`, `maps.Copy`, `maps.DeleteFunc`

**sync:**
- `sync.OnceFunc`, `sync.OnceValue` — instead of `sync.Once` + wrapper

**context:**
- `context.AfterFunc(ctx, cleanup)` — runs cleanup on cancellation
- `context.WithTimeoutCause`, `context.WithDeadlineCause`

**log/slog** — structured logging in stdlib (see Layer 2 § Logging).

### Go 1.22+

**Loops:**
- `for i := range n` instead of `for i := 0; i < n; i++`
- Loop variables are now safe to capture in goroutines (each iteration has its own copy)

**cmp:**
- `cmp.Or`: returns first non-zero value

```go
// Instead of:
name := os.Getenv("NAME")
if name == "" {
    name = "default"
}
// Use:
name := cmp.Or(os.Getenv("NAME"), "default")
```

All arguments are evaluated before the call, so don't use `cmp.Or` when later entries are expensive or have side effects, or when a zero value (`0`, `false`, `""`) is a valid result rather than "missing".

**reflect:**
- `reflect.TypeFor[T]()` instead of `reflect.TypeOf((*T)(nil)).Elem()`

**net/http:**
- `mux.HandleFunc("GET /api/{id}", handler)` — method + path params
- `r.PathValue("id")` to read path params

### Go 1.23+

- `maps.Keys(m)` / `maps.Values(m)` return iterators
- `slices.Collect(iter)` to build slice from iterator
- `slices.Sorted(iter)` collect + sort in one step

```go
keys := slices.Collect(maps.Keys(m))
sortedKeys := slices.Sorted(maps.Keys(m))
for k := range maps.Keys(m) { process(k) }
```

- `time.Tick`: GC can now recover unreferenced tickers, so `for range time.Tick(d)` is fine for simple forever loops. Use `time.NewTicker` when you need `Stop` or `Reset`.

### Go 1.24+

- `t.Context()` in tests (not `context.WithCancel(context.Background())`). It is already canceled when `t.Cleanup` functions run — cleanup that needs a live context must create its own.
- `omitzero` on JSON-tagged bool, numeric, struct and `time.Time` fields whose zero value means "absent". Keep `omitempty` for strings, slices and maps — `omitzero` omits only a nil slice/map, not an empty one, so swapping changes the output.
- `b.Loop()` in benchmarks (not `for i := 0; i < b.N; i++`). `b.N` is known only after the loop ends, so a benchmark that sizes fixtures from `b.N` before the loop must be restructured, not swapped mechanically.
- `strings.SplitSeq` / `strings.FieldsSeq` / `bytes.SplitSeq` / `bytes.FieldsSeq` when iterating split results.

```go
// Before
for _, part := range strings.Split(s, ",") { process(part) }
// After
for part := range strings.SplitSeq(s, ",") { process(part) }
```

### Go 1.25+

- `wg.Go(fn)` instead of `wg.Add(1)` + `go func() { defer wg.Done(); ... }()`
- The function passed to `wg.Go` must not panic. If panic recovery is required, handle it inside the function.

```go
var wg sync.WaitGroup
for _, item := range items {
    wg.Go(func() { process(item) })
}
wg.Wait()
```

### Go 1.26+

- `new(val)` returns pointer to value — instead of `x := val; &x` or a `Ptr[T]` helper whose only job is `&value`.
  An untyped constant takes its default type: `new(30)` is always `*int`, `new("s")` is `*string`. For other types convert explicitly: `new(30 * time.Second)` → `*time.Duration`, `new(int32(3))` → `*int32`. For composite literals keep `&T{...}`.

```go
type Config struct {
    Timeout *time.Duration
    Retries *int
    Debug   *bool
}

cfg := Config{
    Timeout: new(30 * time.Second),
    Retries: new(3),
    Debug:   new(true),
}
```

- `errors.AsType[T](err)` instead of `errors.As(err, &target)`.

```go
if pathErr, ok := errors.AsType[*os.PathError](err); ok {
    handle(pathErr)
}
```

### Go 1.27+

> Go 1.27 is not released yet (expected February 2027). These entries follow upstream's pre-release guidance — confirm on `pkg.go.dev` before relying on exact names.

- **`encoding/json/v2`** for **new** JSON code: stricter defaults (rejects invalid UTF-8 and duplicate keys, encodes nil slices/maps as `[]`/`{}`). Do **not** switch existing `encoding/json` code unless migration is requested — even a compiling import change alters wire output. For a requested migration start with `jsonv1.DefaultOptionsV1()`, test the serialized output, then drop compatibility options one by one.

```go
import (
    jsonv1 "encoding/json"
    json "encoding/json/v2"
)

// New code: v2 defaults → {"Name":"Remi","Nicknames":[]}
body, err := json.Marshal(pet)

// Migration: keep v1 wire behavior first → {"Name":"Remi","Nicknames":null}
body, err := json.Marshal(pet, jsonv1.DefaultOptionsV1())
```

- **Generic methods**: `func (s Set[T]) Map[U any](f func(T) U) []U` instead of a package-level `Map(s, f)` helper, when the operation belongs to the type. Keep package-level helpers for operations that don't.
- **Promoted fields in struct literals**: set fields of an embedded struct directly — `Document{CreatedBy: "alice", Name: "x"}` instead of `Document{AuditInfo: AuditInfo{CreatedBy: "alice"}, Name: "x"}`. Don't mix a promoted field with the embedded field itself; pointer-embedded paths are not supported.
- **`strings.CutLast` / `bytes.CutLast`**: `dir, file, found := strings.CutLast(path, "/")` instead of `LastIndex` + manual slicing.
- **Standard library `uuid`**: `uuid.New()`, `uuid.Parse(raw)` instead of `github.com/google/uuid` or a hand-rolled implementation. Keep the third-party package only for older targets or behavior outside the standard API.
- **`URL.Clone` / `Values.Clone`** (`net/url`): `base.Clone()`, `values.Clone()` instead of manual copies that can share mutable data or miss fields.

---

# Layer 2 — Idiomatic patterns (version-agnostic)

> Sources: [Effective Go](https://go.dev/doc/effective_go), [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments), [Google Go Style Guide](https://google.github.io/styleguide/go/), [Go Proverbs](https://go-proverbs.github.io/). House style taken from [yuriykis/microblocknet](https://github.com/yuriykis/microblocknet) and [anthdm/hollywood](https://github.com/anthdm/hollywood); where those older codebases predate a modern idiom (quit channels, `time.Sleep` loops, `if v == ""` defaults), this skill follows the modern idiom.

## Errors

**Wrap with `%w` only when the caller benefits from unwrapping.** Use `%v` (or rebuild the message) when you only want context.

```go
// Caller may want errors.Is(err, os.ErrNotExist) — wrap
return fmt.Errorf("load config: %w", err)

// Caller only logs — %v is fine, prevents leaking internal error types
return fmt.Errorf("load config: %v", err)
```

- **The prefix names the operation, not the failure**: `load config: %w`, not `failed to load config: %w` — otherwise a wrapped chain reads "failed to … failed to … failed to …".
- **`errors.New` when there is nothing to format**: `errors.New("block signature is invalid")`, not `fmt.Errorf("block signature is invalid")`.

**Sentinel errors** for stable comparison points; **typed errors** when callers need structured data.

```go
// Sentinel
var ErrNotFound = errors.New("not found")

// Typed
type NotFoundError struct { ID string }
func (e *NotFoundError) Error() string { return fmt.Sprintf("not found: %s", e.ID) }
```

- Match sentinels with `errors.Is`; match types with `errors.As` (Go ≤1.25) or `errors.AsType[T]` (Go 1.26+).
- **Do not log AND return** the same error — caller decides whether to log. Pick one.
- **Do not wrap if you have nothing to add** — repeated `fmt.Errorf("%w", err)` is noise.
- Errors are values, not exceptions. Don't `panic` for expected failures.

## Interfaces

**Define interfaces at the consumer, not the producer.** The package that *uses* an abstraction owns it.

```go
// Bad: producer defines an interface "in case someone needs it"
package store
type Store interface { Get(id string) (Item, error) }
type pgStore struct { ... }

// Good: producer returns concrete; consumer defines minimal interface it needs
package store
type PG struct { ... }
func (p *PG) Get(id string) (Item, error) { ... }

package report
type itemGetter interface { Get(id string) (store.Item, error) }
func Build(g itemGetter, ids []string) { ... }
```

**Exception — a port with several interchangeable implementations.** When a package itself ships several implementations of one role (an in-memory and a Mongo store; an engine's pluggable `Remoter`), define the interface next to them. A factory that picks the implementation from config returns that interface.

```go
package store

type BlockStorer interface {
    Put(ctx context.Context, b *proto.Block) error
    Get(ctx context.Context, hash string) (*proto.Block, error)
}

type MemoryBlockStore struct { ... } // implements BlockStorer
type MongoBlockStore struct { ... }  // implements BlockStorer

func NewBlockStore(kind string) (BlockStorer, error) {
    switch kind {
    case "memory":
        return NewMemoryBlockStore(), nil
    case "mongo":
        ...
    default:
        return nil, fmt.Errorf("unknown store type %q", kind)
    }
}
```

**Keep interfaces small.** `io.Reader`, `io.Writer`, `fmt.Stringer` — one or two methods is the norm. Compose larger roles from small ones (`Storer` exposing `BlockStore()`, `TxStore()`, `UTXOStore()`).

**Accept interfaces, return structs.** Functions take the smallest interface they need; constructors return the concrete type so callers see the full API. The only constructor that returns an interface is a factory choosing between implementations (above).

**Don't add an interface speculatively.** Add it when you have a second implementation or a real testing need.

## Constructors and options

- **`New...` constructors**; return `(*T, error)` when setup can fail. Never `log.Fatal` or `panic` inside a constructor — return the error.
- **Inject dependencies through the constructor** (logger, stores, clients), not through globals.
- **Functional options** for optional settings with defaults — the hollywood style:

```go
type Opts struct {
    InboxSize   int
    MaxRestarts int32
    Middleware  []MiddlewareFunc
}

type OptFunc func(*Opts)

func DefaultOpts() Opts {
    return Opts{InboxSize: defaultInboxSize, MaxRestarts: defaultMaxRestarts}
}

func WithInboxSize(n int) OptFunc {
    return func(o *Opts) { o.InboxSize = n }
}

func (e *Engine) Spawn(p Producer, kind string, opts ...OptFunc) *PID {
    options := DefaultOpts()
    for _, opt := range opts {
        opt(&options)
    }
    ...
}
```

- **Config value with `With...` methods** when a config is built once and passed in: value receiver, returns the modified copy.

```go
func NewEngineConfig() EngineConfig { return EngineConfig{} }

func (c EngineConfig) WithRemote(r Remoter) EngineConfig {
    c.remote = r
    return c
}

engine, err := actor.NewEngine(actor.NewEngineConfig().WithRemote(r))
```

- **Builder** only for genuinely multi-step initialization (create service → start transports → bootstrap peers), where each step can fail. Don't use it for what options cover.

## Middleware (decorator)

Cross-cutting concerns — metrics, logging, tracing — wrap the next layer instead of being written into business logic.

**Function middleware** (hollywood): a middleware takes the next handler and returns a new one; apply in reverse so the first listed runs outermost.

```go
type ReceiveFunc = func(*Context)
type MiddlewareFunc = func(ReceiveFunc) ReceiveFunc

func applyMiddleware(rcv ReceiveFunc, mw ...MiddlewareFunc) ReceiveFunc {
    for i := len(mw) - 1; i >= 0; i-- {
        rcv = mw[i](rcv)
    }
    return rcv
}
```

**Interface decorator** (microblocknet): a struct implements the same interface and delegates to `next`. A named `err` result lets the deferred function see the outcome; passing `time.Now()` as an argument captures the start time at `defer`.

```go
type metricsMiddleware struct {
    requests prometheus.Counter
    errors   prometheus.Counter
    latency  prometheus.Histogram
    next     NodeServer
}

func (m *metricsMiddleware) Handshake(ctx context.Context, v *proto.Version) (_ *proto.Version, err error) {
    defer func(begin time.Time) {
        m.requests.Inc()
        m.latency.Observe(time.Since(begin).Seconds())
        if err != nil {
            m.errors.Inc()
        }
    }(time.Now())
    return m.next.Handshake(ctx, v)
}
```

## Packages

- **Name**: single word, lowercase, no underscores; describes purpose, not contents. `http`, `bytes`, `parser` — not `httpUtils`, `parserStuff`.
- **Avoid grab-bag packages**: no `helpers`, `misc`, `shared`, or a `util`/`common` that collects unrelated code — they become circular-import magnets. Two narrow uses are fine: a `common` module in a multi-module workspace that holds only the shared contract (protobuf types, crypto primitives), and a test-only `util` package of fixture generators (`RandomBlock()`, `RandomTx()`).
- **Don't organize by kind.** Files like `errors.go`, `types.go`, `interfaces.go` group by language construct rather than by behavior. Group by concern: `user.go`, `user_repository.go`, `user_test.go`.
- **`internal/`** to enforce module-private packages. Use it; it's the canonical Go way.
- **`pkg/`** is unnecessary in most projects. Put packages at module root or under `internal/`.
- **No package-level mutable state** unless it's a documented singleton (e.g., `http.DefaultClient`). Even then, prefer explicit dependency passing.
- **`init()` functions**: only for trivial registration. Anything that can fail or do I/O belongs in an explicit `New`/`Setup` func.

## Testing

- **Assertions with [`testify`](https://github.com/stretchr/testify)** — the house style. `require` for preconditions after which the test can't continue (setup errors), `assert` for the checks themselves. In a module that deliberately avoids third-party test dependencies, use plain `t.Fatalf` / `t.Errorf` instead.
- **One test per scenario** (`TestChainAddBlock`, `TestChainAddBlockWithTxs`) when the setup differs between cases; **table-driven** with subtests when many inputs go through the same steps:

```go
func TestParse(t *testing.T) {
    tests := []struct {
        name    string
        in      string
        want    Result
        wantErr bool
    }{
        {"empty", "", Result{}, true},
        {"valid", "x=1", Result{X: 1}, false},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := Parse(tt.in)
            if tt.wantErr {
                assert.Error(t, err)
                return
            }
            require.NoError(t, err)
            assert.Equal(t, tt.want, got)
        })
    }
}
```

- **`t.Helper()`** at the top of test helpers — failures point to the call site, not the helper.
- **`t.Cleanup(fn)`** instead of `defer` for teardown — composable across helpers.
- **`t.TempDir()`** — auto-cleaned, beats `os.MkdirTemp`.
- **`t.Context()`** (Go 1.24+) — auto-cancels at test end.
- **`testdata/`** for fixtures — Go tooling ignores this directory by convention.
- **Black-box tests** (`package foo_test`) when you only want to test the public API; **white-box** (`package foo`) when you need internal access.
- **Avoid heavy mocking.** Prefer real implementations or in-memory fakes. Mocking everything tests the mock, not the code.

## Concurrency

- **Always propagate `context.Context`** — first parameter, named `ctx`.
- **Every goroutine must have a clear termination path** — usually `ctx.Done()`. Goroutine leaks are bugs.
- **Don't communicate by sharing memory; share memory by communicating** — but `sync.Mutex` is correct when the state is local to one struct.
- **`sync.Mutex`/`sync.RWMutex`**: zero value is usable; never copy a `Mutex` (the `vet` copylocks check catches this).
- **Channels**: unbuffered for synchronization; buffered only when you can prove the buffer size from the design (not "to be safe").
- **`errgroup.Group`** (`golang.org/x/sync/errgroup`) for groups of goroutines that may error and share a context.
- **Don't start a goroutine you can't stop.** If the function spawns one, document its lifecycle and provide a stop signal. A bare "fire-and-forget" `go broadcast(x)` needs a context with a timeout (or a bounded worker) so a slow peer can't pile up goroutines.
- **Background loops**: `select` on `ctx.Done()` and a ticker, not `time.Sleep` in a `for` loop — a sleeping loop can't be stopped until the sleep ends.

```go
func (n *Node) syncLoop(ctx context.Context) {
    ticker := time.NewTicker(syncInterval)
    defer ticker.Stop()
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            n.sync(ctx)
        }
    }
}
```

  Per-loop quit channels (`quitCh chan struct{}` closed in `Stop()`) work, but one context canceled in `Stop()` replaces all of them and also reaches the calls the loop makes.
- **Actor-style components** (hollywood): state belongs to the actor and is touched only inside `Receive`, so it needs no mutex; dispatch on the message type with a type switch.

```go
func (f *foo) Receive(c *actor.Context) {
    switch msg := c.Message().(type) {
    case actor.Started:
        ...
    case *message:
        f.count++ // safe: Receive runs one message at a time
    }
}
```

## Naming

- **Short names in small scopes, longer in larger.** `i` for a loop index is fine; `userIndex` for the same is noise.
- **Acronyms keep case**: `URL`, `ID`, `HTTP` — `userID`, `parseURL`, not `userId` or `parseUrl`.
- **Receiver names**: 1–2 characters, consistent across all methods of a type. `func (b *Buffer) ...` everywhere — never mix `b` and `self` and `this`.
- **Don't repeat the package name**: `http.Server` not `http.HTTPServer`; `bytes.Buffer` not `bytes.BytesBuffer`.
- **No `Get` prefix** for accessors: `obj.Name()` and `obj.SetName(x)`. `Get` is OK if there's genuine retrieval semantics (HTTP `Get`).
- **Errors**: variables `ErrXxx`; types `XxxError`.
- **Interfaces**: single-method interfaces named after the method + `-er` (`Reader`, `Stringer`, `Closer`). A multi-method interface describing a role takes the role noun + `-er` (`Storer`, `BlockStorer`, `Remoter`, `Processer`, `Noder`).

## Logging

- Use **`log/slog`** (Go 1.21+) for structured logging. The old `log` package is fine for tools but doesn't carry attributes.

```go
slog.Info("processed request", "user_id", userID, "duration_ms", elapsed.Milliseconds())
```

- Pass a `*slog.Logger` as a dependency — don't reach for a global. Test with `slog.New(slog.NewTextHandler(io.Discard, nil))` to silence in tests.
- Levels: `Debug` for dev-only, `Info` for normal flow, `Warn` for recoverable issues, `Error` for failures the caller couldn't handle.

## Configuration

- Prefer **flags + env vars** over config files for command-line tools.
- Group config in a single struct + a `Load()` function. Don't scatter `os.Getenv` calls across the codebase.
- Defaults as named constants; env fallback with `cmp.Or` (Go 1.22+) instead of `if v == "" { v = default }`:

```go
const defaultListenAddr = ":4000"

cfg := ServerConfig{
    ListenAddr: cmp.Or(os.Getenv("LISTEN_ADDR"), defaultListenAddr),
}
```
- Document defaults in code, not in a separate `defaults.md`.

## Documentation

- **Every exported identifier** has a doc comment starting with the identifier's name: `// Parse reads ...`.
- **Package comment** in one file: `// Package foo does X.`
- Keep comments about *what is unusual* — well-named identifiers handle the obvious.

---

# What this skill does NOT cover

- **Project layout decisions** (DDD, hexagonal, Clean Architecture, monolith vs microservices) — those depend on the project, not the language.
- **Specific frameworks** (Gin, Echo, urfave/cli, cobra, sqlx, GORM, etc.) — refer to their docs.
- **CGo, build tags, cross-platform conditional compilation** — read the official [build constraints docs](https://pkg.go.dev/cmd/go#hdr-Build_constraints) for those.
- **Performance/profiling, SIMD, assembly** — out of scope; refer to `pprof` docs.
- **Anything in `golang.org/x/exp`** — experimental, treat as moving target.

# Verification rules (anti-hallucination)

- This skill's version table was last verified against **Go 1.26.x**; the Go 1.27 entries are pre-release. Prefer the project's `go.mod` and official docs over this file if they disagree.
- If you are unsure whether a function/method exists or behaves as described here, **check `pkg.go.dev` or write a tiny test** — do not guess.
- If a rule in this skill conflicts with what `gofmt`, `go vet`, or `staticcheck` says about real code, the tool wins. Tell the user.
- If the user asks for a pattern this skill labels "Avoid" and gives a good reason, follow the user. The skill is guidance, not law.
