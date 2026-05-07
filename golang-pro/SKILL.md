---
name: golang-pro
description: Idiomatic, modern Go for any Go project. Two layers — (1) modern syntax/stdlib per Go version (1.0–1.26), (2) idiomatic patterns for errors, interfaces, packages, testing, concurrency, naming. Use when writing or reviewing Go code.
---

# Golang Pro

A two-layer skill for writing idiomatic Go.

- **Layer 1** — modern syntax/stdlib features per Go version (sourced from JetBrains/go-modern-guidelines)
- **Layer 2** — idiomatic patterns the version-table doesn't cover (errors, interfaces, packages, testing, concurrency, naming)

## Detected Go Version

!`grep -rh "^go " --include="go.mod" . 2>/dev/null | cut -d' ' -f2 | sort | uniq -c | sort -nr | head -1 | xargs | cut -d' ' -f2 | grep . || echo unknown`

## How to use

Use the version detected above when available. If detection returns `unknown`, do a quick nearest-module check before asking: look for `go.mod` in the current workspace/module root relevant to the user's task. If still unknown, ask the user.

**If version detected:**
- Briefly tell the user: "Targeting Go X.XX — using language features and stdlib up to that version, plus idiomatic patterns."
- Do NOT enumerate features. Do NOT ask for confirmation.

**If "unknown" after the nearest-module check:**
- Ask: "Could not detect Go version. Which to target? [1.23 / 1.24 / 1.25 / 1.26]"

**While writing or reviewing Go code, apply BOTH layers:**
- Layer 1: prefer modern features available at target version; never use newer.
- Layer 2: apply regardless of version.

---

# Layer 1 — Modern syntax/stdlib by version

> Source: [JetBrains/go-modern-guidelines](https://github.com/JetBrains/go-modern-guidelines), MIT-licensed. Update by re-syncing this section.

### Go 1.0+
- `time.Since`: `time.Since(start)` instead of `time.Now().Sub(start)`

### Go 1.8+
- `time.Until`: `time.Until(deadline)` instead of `deadline.Sub(time.Now())`

### Go 1.13+
- `errors.Is`: `errors.Is(err, target)` instead of `err == target` (works with wrapped errors)

### Go 1.18+
- `any`: use `any` instead of `interface{}`
- `bytes.Cut` / `strings.Cut`: `before, after, found := strings.Cut(s, sep)` instead of Index+slice

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
- `strings.Clone` / `bytes.Clone`: copy without sharing memory
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
- `slices.SortFunc(items, func(a, b T) int { return cmp.Compare(a.X, b.X) })`
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

- `time.Tick`: GC can now recover unreferenced tickers; `Stop` no longer required to help GC.

### Go 1.24+

- `t.Context()` in tests (not `context.WithCancel(context.Background())`).
- `omitzero` (not `omitempty`) for `time.Duration`, `time.Time`, structs, slices, maps in JSON tags.
- `b.Loop()` in benchmarks (not `for i := 0; i < b.N; i++`).
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

- `new(val)` returns pointer to value (no more `x := val; &x`).
  Type is inferred: `new(0)` → `*int`, `new("s")` → `*string`, `new(T{})` → `*T`.

```go
cfg := Config{
    Timeout: new(30),   // *int
    Debug:   new(true), // *bool
}
```

- `errors.AsType[T](err)` instead of `errors.As(err, &target)`.

```go
if pathErr, ok := errors.AsType[*os.PathError](err); ok {
    handle(pathErr)
}
```

---

# Layer 2 — Idiomatic patterns (version-agnostic)

> Sources: [Effective Go](https://go.dev/doc/effective_go), [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments), [Google Go Style Guide](https://google.github.io/styleguide/go/), [Go Proverbs](https://go-proverbs.github.io/). Patterns cross-checked against [boltdb/bolt](https://github.com/boltdb/bolt) and [ThreeDotsLabs/wild-workouts-go-ddd-example](https://github.com/ThreeDotsLabs/wild-workouts-go-ddd-example).

## Errors

**Wrap with `%w` only when the caller benefits from unwrapping.** Use `%v` (or rebuild the message) when you only want context.

```go
// Caller may want errors.Is(err, os.ErrNotExist) — wrap
return fmt.Errorf("load config: %w", err)

// Caller only logs — %v is fine, prevents leaking internal error types
return fmt.Errorf("load config: %v", err)
```

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

**Keep interfaces small.** `io.Reader`, `io.Writer`, `fmt.Stringer` — one or two methods is the norm.

**Accept interfaces, return structs.** Functions take the smallest interface they need; constructors return the concrete type so callers see the full API.

**Don't add an interface speculatively.** Add it when you have a second implementation or a real testing need.

## Packages

- **Name**: single word, lowercase, no underscores; describes purpose, not contents. `http`, `bytes`, `parser` — not `httpUtils`, `parserStuff`.
- **Avoid grab-bag packages**: no `util`, `helpers`, `common`, `shared`, `misc`. They become circular-import magnets.
- **Don't organize by kind.** Files like `errors.go`, `types.go`, `interfaces.go` group by language construct rather than by behavior. Group by concern: `user.go`, `user_repository.go`, `user_test.go`.
- **`internal/`** to enforce module-private packages. Use it; it's the canonical Go way.
- **`pkg/`** is unnecessary in most projects. Put packages at module root or under `internal/`.
- **No package-level mutable state** unless it's a documented singleton (e.g., `http.DefaultClient`). Even then, prefer explicit dependency passing.
- **`init()` functions**: only for trivial registration. Anything that can fail or do I/O belongs in an explicit `New`/`Setup` func.

## Testing

- **Table-driven** with subtests:

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
            if (err != nil) != tt.wantErr {
                t.Fatalf("err = %v, wantErr = %v", err, tt.wantErr)
            }
            if got != tt.want {
                t.Errorf("got %v, want %v", got, tt.want)
            }
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
- **Don't start a goroutine you can't stop.** If the function spawns one, document its lifecycle and provide a stop signal.

## Naming

- **Short names in small scopes, longer in larger.** `i` for a loop index is fine; `userIndex` for the same is noise.
- **Acronyms keep case**: `URL`, `ID`, `HTTP` — `userID`, `parseURL`, not `userId` or `parseUrl`.
- **Receiver names**: 1–2 characters, consistent across all methods of a type. `func (b *Buffer) ...` everywhere — never mix `b` and `self` and `this`.
- **Don't repeat the package name**: `http.Server` not `http.HTTPServer`; `bytes.Buffer` not `bytes.BytesBuffer`.
- **No `Get` prefix** for accessors: `obj.Name()` and `obj.SetName(x)`. `Get` is OK if there's genuine retrieval semantics (HTTP `Get`).
- **Errors**: variables `ErrXxx`; types `XxxError`.
- **Interfaces**: single-method interfaces named after the method + `-er` (`Reader`, `Stringer`, `Closer`).

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

- This skill's version table was last verified against **Go 1.26.x**. Prefer the project's `go.mod` and official docs over this file if they disagree.
- If you are unsure whether a function/method exists or behaves as described here, **check `pkg.go.dev` or write a tiny test** — do not guess.
- If a rule in this skill conflicts with what `gofmt`, `go vet`, or `staticcheck` says about real code, the tool wins. Tell the user.
- If the user asks for a pattern this skill labels "Avoid" and gives a good reason, follow the user. The skill is guidance, not law.
