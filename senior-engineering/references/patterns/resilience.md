# Resilience patterns

Read when code calls something outside its process — a database, another service, a provider's API, a
message broker — or accepts load it must survive, and when a review finds one of these patterns. A
slow or failing dependency is one of the failure properties a design must decide (`references/design.md`
"Concurrency and idempotency"); this file says how. The resilience library, if any, is the stack
playbook's choice. Caching is its own topic (`references/caching.md`).

## Contents
- Decide per dependency
- Timeout
- Retry
- Circuit breaker
- Bulkhead
- Fallback and degradation
- Rate limiting and load shedding
- Composing them
- Messaging
- Testing and observing
- Patterns left out

## Decide per dependency

Resilience is decided per outside dependency, not sprinkled on every call. The technical spec holds one
row per dependency; each column is a decision, and "none" is a valid, stated answer:

| Dependency | Timeout | Retry | Idempotent? | Breaker | Bulkhead | When it fails, the user sees |
|---|---|---|---|---|---|---|
| payment provider | 5 s | no — not idempotent without a key | with key | yes | own pool | "payment pending", reconciled later |
| product search | 800 ms | 1, with jitter | yes | yes | own pool | cached results, marked as possibly stale |

- **The last column is the decision that matters.** A failure the design never answered becomes a
  stack trace, a hung request or a silent wrong answer.
- **A resilience pattern is a decorator around the port's adapter** (`references/patterns/code.md`),
  configured in the composition root. Use cases do not loop, sleep or count failures.

## Timeout

- **Every call that leaves the process has a timeout** — connect and request both, and a client's
  default is usually infinite or minutes long. A call without one holds a thread, a connection and the
  caller's request until something else gives up.
- **Choose it from the dependency's measured latency**: the percentile that matches the false-timeout
  rate you accept (a timeout at p99.9 fails one healthy call in a thousand), plus padding for the
  network. A guessed round number is a bug waiting for load.
- **Propagate the deadline.** A call made while serving a request gets the time that request has left,
  minus a margin — not a fresh, fixed timeout. Work whose deadline has passed is skipped; nobody is
  waiting for its answer.
- **Cancel what the caller abandoned.** When the request is cancelled or times out, its outstanding
  downstream calls are cancelled too.

## Retry

Retries are selfish: each one spends the dependency's capacity to raise one call's chance. They help
with brief, transient faults and make overload worse.

- **Retry only what can succeed next time** — timeouts, connection failures, explicit "try again"
  responses (429, 503, a deadlock victim). Never a validation error, an authorization failure, a not
  found or a business rule.
- **Retry only what is safe to repeat** — a read, a naturally idempotent write, or a write carrying an
  idempotency key the receiver honours (`design.md` "Concurrency and idempotency"). A timed-out
  payment may have succeeded; retrying it blindly charges twice.
- **Retry at one layer.** Three attempts at each of five layers is up to 243 calls at the bottom for
  one user action. Pick the layer closest to the failing dependency; the layers above do not retry.
- **Back off exponentially, with jitter, up to a cap**, and stop after a small number of attempts —
  typically two or three. Without jitter, every client retries in step and the recovering dependency
  receives synchronized waves.
- **Honour the server's answer**: a `Retry-After` is a minimum wait, and an overload response means
  back off, not try harder.
- **Bound retries across all calls, not only per call** — a retry budget (retries allowed while they
  stay a small share of the traffic) or a circuit breaker, so a dependency that is down is not hit by
  a multiple of normal load.
- **All attempts together fit inside the caller's deadline.** A retry that will outlive the request it
  serves is waste.
- **Misuse**: retrying everything on every exception; retrying non-idempotent writes; a retry loop
  inside a use case; retries in the client and the gateway and the service, all at once.

## Circuit breaker

- **Problem**: a dependency is down or overloaded for longer than a retry can bridge. Callers keep
  waiting for timeouts, tie up their own threads and connections, and the failure spreads.
- **Earns its place** on a remote dependency whose outage would otherwise exhaust the caller's
  resources, called often enough for failure rates to mean something.
- **Shape**: closed — calls pass and failures are counted over a time window; open — calls fail at once
  without reaching the dependency; half-open — after a wait, a few trial calls decide whether to close
  again or reopen. Thresholds come from the dependency's normal error rate, not a guess.
- **One breaker per independent failure domain** — per dependency, and per shard, region or tenant
  when those fail independently. One breaker for a sharded store blocks the healthy shards too.
- **The retry stops when the breaker is open**; an open breaker is not a transient fault.
- **An open breaker is an answer the caller must handle** — the fallback, or a clear "temporarily
  unavailable". Each state change is logged and is a metric someone is alerted on.
- **Not for**: in-process calls; consumers of a queue, where redelivery and a dead-letter queue already
  isolate the failure; a dependency the platform or service mesh already guards.

## Bulkhead

- **Problem**: one slow dependency consumes the shared pool — threads, connections, concurrency — and
  every other feature stops with it.
- **Earns its place** where several dependencies or tenants share one pool and one of them can be slow
  while the others are not.
- **Shape**: a bounded pool or concurrency limit per dependency, or per class of consumer, with a
  bounded queue and a stated answer when both are full — reject at once, never wait unbounded. At
  larger scale the same idea separates processes, instances, queues or whole cells per tenant group.
- **Use the platform's limits first** — connection-pool sizes, container resource limits, a gateway's
  per-client quota — before writing one.
- **Misuse**: pools sized by guess so that the bulkhead itself throttles healthy traffic; a bulkhead
  with an unbounded queue, which only moves the pile-up.

## Fallback and degradation

- **A fallback gives a lesser answer when the real one fails**: cached or default data, a reduced
  feature, a generic recommendation instead of a personal one. It fits where a degraded answer is still
  correct enough for the business and the user is told it is degraded.
- **Never a silent fallback for money, security or correctness.** Skipping a fraud check, treating an
  unknown balance as zero, or approving because the authorization service timed out turns an outage
  into a loss.
- **Where the step is essential, prefer accept-and-reconcile to a fake answer**: record the operation
  as pending in durable storage, tell the user so, and let a background process verify and complete or
  compensate it once the dependency is back — with a switch to refuse instead when risk rises.
- **A fallback hides the failure from everything outside it** — the breaker, the metrics, the caller.
  Count and log each one, so a dependency that has been down for a day is visible.
- **Degradation is designed in advance**: what triggers it, what is switched off, which layer does it.
  The degraded path runs rarely, so it is tested on purpose, or it is broken when needed.

## Rate limiting and load shedding

- **Protect yourself.** An inbound limit per client, key or tenant stops one caller from taking the
  capacity of all. The rejection is cheap and early, with 429 and `Retry-After` on HTTP (RFC 6585,
  RFC 9110), and the limit is documented in the contract.
- **Shed load before you fall over.** Under overload, reject early on a signal of saturation — queue
  length, concurrency, latency — rather than accepting work that will time out anyway. Shed background
  and low-priority work before interactive requests.
- **Respect the limits of what you call.** A provider's quota is a constraint of the design: throttle
  outbound calls to it, queue the excess, and treat its 429 as back off, never as retry now.
- **Use the gateway's or platform's limiter** where one exists; a distributed limit hand-written in
  application code needs shared state and its own failure answer.

## Composing them

Most calls need two or three of these, not all. When several wrap one call, the order, from the
caller inward, is:

```
fallback → total timeout → retry → circuit breaker → bulkhead → per-attempt timeout → call
```

- the per-attempt timeout is innermost, so a hung attempt becomes a failure the retry can see;
- the breaker sits inside the retry, so it counts every attempt and its open state stops the retry;
- the total timeout bounds all attempts together, within the caller's deadline;
- the fallback is outermost, and only where one was decided.

The stack is composed once, in the composition root, and its order is stated where it is configured.

## Messaging

A message consumer's resilience is the broker's redelivery, not a retry loop around the handler:
bounded redelivery with backoff, a dead-letter queue for what still fails, and an idempotent consumer
because delivery is at least once (`references/architecture/event-driven.md`). A poison message is
moved aside and alerted on, never retried forever while the queue behind it waits.

## Testing and observing

- **Inject the failure for real.** Integration tests run the dependency in a container behind a
  fault-injecting proxy or a stub server that delays, drops and errors (`references/testing.md`), and
  prove: the timeout fires, the retry stops at its limit and only for retryable errors, the breaker
  opens and recovers, the bulkhead rejects, the fallback's answer is the decided one.
- **Test the duplicate**: the retried write, the redelivered message, applied twice, leave one effect.
- **Every retry, breaker state change, rejection and fallback is logged and counted**, tagged with the
  dependency. Without that, resilience turns a visible outage into an invisible degradation.

## Patterns left out

- **Hedging** — sending a second request before the first answers, for tail latency. Only for
  idempotent reads with a measured tail problem; it adds load by design.
- **Cache-aside and stale-while-revalidate** — `references/caching.md`.
- **Health endpoints, liveness and readiness** — operations, recorded with the deployment; a readiness
  check that fails under load can restart a struggling service into a worse state.
- **Compensation and sagas** — `references/architecture/event-driven.md`.
