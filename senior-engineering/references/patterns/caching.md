# Caching

Read when a design adds a cache at any layer, when a read is too slow or a dependency too loaded, and
when a review finds a cache. A cache is a copy of data that is allowed to be wrong for a while: every
cache is a decision about staleness, a new dependency and a security boundary, not a performance
setting. `references/principles/design.md` "Balance" governs — a cache names a measured problem.

## Contents
- Decide before caching
- Where to cache
- Read and write patterns
- Invalidation and freshness
- Stampede and cold start
- Keys and values
- Negative caching and errors
- Security
- What not to cache
- Testing and observing
- Left out

## Decide before caching

- **Measure first.** A cache earns its place where a profile or a load test shows the read is the
  bottleneck and the same result is requested again and again. A cache in front of a fast query, or of
  data nobody reads twice, adds a dependency and a staleness bug for no gain. Fix the query, the index
  or the payload before caching it.
- **The business decides the staleness.** How old may this data be when someone sees it, and what
  harm does an old value do? That answer sets the expiry, the pattern and whether to cache at all.
- **Each cache is recorded** in the technical spec, one row per cached data set; each column is a
  decision:

| Data | Layer | Pattern | Staleness allowed | Invalidated by | Key | When the cache is down |
|---|---|---|---|---|---|---|
| `<data set>` | `<layer>` | `<pattern>` | `<from the business>` | `<TTL, event, write path>` | `<inputs>` | `<what happens>` |

- **A cache sits behind a port** like any outside dependency, usually as a decorator around the
  adapter it speeds up (`references/patterns/code.md`). Use cases do not read or write a cache inline.

## Where to cache

| Layer | Good for | Watch out for |
|---|---|---|
| **Client and browser** | static assets, a user's own data for a short time | you cannot invalidate it; only the response's caching headers control it |
| **CDN or reverse proxy** | public, identical-for-everyone responses | personal data leaking between users; poisoning (see Security) |
| **Gateway** | a whole response for many callers | the same as the CDN, and hiding the service's own load from its metrics |
| **In-process, per instance** | small, hot, rarely changing data — reference data, configuration | each instance holds a different copy; load on the source grows with the fleet; every deploy starts cold |
| **Shared cache service** | data many instances read, larger sets, surviving deploys | another system to run, often less available than the store it fronts; a network hop per read |
| **In the database** | a read model, a materialized view, a read replica | replica lag is staleness too (`references/patterns/application.md` "The read side") |

- **HTTP caching follows the standard** (RFC 9111): `Cache-Control` decides who may store a response —
  `private` keeps it out of shared caches, `no-store` out of every cache, `no-cache` forces
  revalidation — and `ETag` with conditional requests lets a client revalidate cheaply. Set the
  headers deliberately on every response; a missing header leaves the decision to each cache's
  heuristics.
- **Two layers caching the same data** multiply the staleness: the worst age is the sum of both.

## Read and write patterns

- **Cache-aside — the default.** Read: look in the cache; on a miss, load from the store and put the
  result in the cache. Write: write the store, then delete the cache entry. The application stays in
  control, and a cache outage degrades to reading the store.
- **Read-through** — the application asks only the cache, which loads from the store on a miss. One
  read path, but the cache is now part of the read's availability.
- **Write-through** — the write goes through the cache to the store in one operation, so a read right
  after a write sees the new value. Every write pays for the cache, including data nobody reads.
- **Write-behind** — the cache accepts the write and stores it later. It loses every write the cache
  holds when it fails; use it only where losing writes is acceptable, and record that decision. Never
  for business data of record.
- **Refresh-ahead and soft and hard expiry** — reload an entry in the background before it expires:
  after the soft expiry the next read triggers a refresh while still being served, and only after the
  hard expiry must it wait. If the refresh fails, the old value keeps serving until the hard expiry.
- **Stale-while-revalidate and stale-if-error** (RFC 5861 for HTTP; the same idea in application
  caches) — serve the expired value while refreshing it, or when the source fails. Both are decided
  fallbacks with a bound on how stale, and each use is counted (`references/patterns/resilience.md`).

## Invalidation and freshness

- **Expiry comes from the staleness the business allows**, not from a default. Too short and the cache
  only adds a hop; too long and users act on old data.
- **Update the store first, then delete the cache entry.** Deleting first lets a concurrent reader load
  the old value from the store and put it back.
- **Delete rather than overwrite.** A delete repeated or reordered leaves the same state; two
  concurrent writers overwriting the cache can leave the older value in it for the whole expiry. Even
  with delete, a reader that loaded before the write can put the old value back — a short expiry, or a
  version or lease check on the put, bounds that race.
- **Invalidate from the write, not from a guess.** When another service owns the data, its change
  events drive the invalidation, published through an outbox (`references/architecture/event-driven.md`);
  expiry remains the backstop for a missed event.
- **Versioned keys** — the data's version or a generation number in the key — make invalidation a key
  change instead of a delete across many entries.
- **In-process caches across instances** need a broadcast invalidation, or an expiry short enough that
  instances disagreeing for that long is acceptable.
- **Read-your-own-writes**: after users change something, they must see the change — read their own
  data from the source, or write it through, for that path.

## Stampede and cold start

- **One load per key at a time.** When a hot entry expires, every concurrent miss goes to the store at
  once. Coalesce concurrent misses into one load — a single-flight per key in process, a lock or lease
  in a shared cache — and let the others wait for it or take the old value.
- **Refresh hot entries early**, before they expire: probabilistic early expiration, where each read
  near the expiry has a rising chance to refresh, spreads the reloads without coordination (Vattani et
  al., "Optimal Probabilistic Cache Stampede Prevention").
- **Jitter the expiry**, so entries written together do not all expire together.
- **Plan the cold start**: a new instance, a flushed cache, a failed cache node. Warm what is
  essential before taking traffic, or limit the rate of loads.
- **The store must survive the cache being gone.** A cache outage sends all its traffic to the store;
  protect the store with load shedding and limits on concurrent loads (`resilience.md`), and run a
  load test with the cache disabled. A system that only works with a warm cache has a hidden capacity
  failure.

## Keys and values

- **The key holds every input that changes the result, and nothing else**: the identifier, the tenant,
  the user or permission scope where the result differs per user, the locale, the representation
  version. A missing input serves one caller's answer to another; an extra one splits the cache and
  kills the hit rate.
- **Normalize the key** — case, order of parameters, default values — so equal requests map to one
  entry, and namespace it by data set and format version.
- **Version the cached format.** During a deploy, old and new code read each other's entries; a reader
  that cannot handle the other version treats the entry as a miss, never crashes on it. Changing the
  format by changing the namespace avoids that, at the cost of a cold start.
- **Bound what is stored**: size per entry, total size and an eviction policy, chosen for the access
  pattern. An expensive-to-rebuild entry may need its own policy.
- **Cache the projection, not the aggregate**: the read model a query returns, shaped for the reader.

## Negative caching and errors

- **Cache "not found"** with a shorter expiry when misses are frequent — repeated lookups of a missing
  key otherwise hit the store every time, which is also a cheap attack.
- **Never cache a transient error as the answer.** A timeout cached as "not found" serves a false
  answer for the whole expiry.
- **The last good value on error** is a fallback decided per data set, with its staleness bound; an
  error cached briefly is another option, so a failing source is not hammered by every request.

## Security

- **Secrets, credentials and tokens are never cached in plain form**, and never in a cache shared
  with other systems. Sensitive data in a shared cache is encrypted in transit and at rest, and the
  cache gets the same access control as the store.
- **Per-user data is keyed per user, or kept out of shared caches.** HTTP responses with personal data
  carry `private` or `no-store`; a shared cache must not reuse a response to an authenticated request
  unless the response explicitly allows it (RFC 9111).
- **Authorize before you serve from the cache.** A cached result is still subject to "may this caller
  see this" — either the permission scope is part of the key, or the check runs on every hit.
- **Cache poisoning**: an input the cache does not key on — a forwarded-host header, an unkeyed query
  parameter — changes the response, and the poisoned response is served to everyone. Every input that
  changes the response is in the key, normalized against an allowlist; `Vary` alone is not a reliable
  fix across CDNs (PortSwigger, "Practical Web Cache Poisoning").
- **Cache deception**: a private response stored under a path that looks static. The cache's rules
  key on the response's headers, not on the path's extension.
- **Timing**: a hit answers faster than a miss and can reveal what another user requested; where that
  matters, the data is not shared across users.

## What not to cache

- **A command never decides from cached data.** A balance or a stock level may be cached for display;
  the decision to withdraw or sell reads the store and is protected by an optimistic concurrency token
  or a constraint (`design.md` "Concurrency and idempotency").
- **Aggregates loaded for a write** come from the store, never from a cache — a write based on a
  stale copy is a lost update.
- **Data with a low hit rate, cheap queries, and data that must be exact for every reader** — a cache
  there adds cost and staleness with nothing to show for it.
- **Session state as cache-only** — if losing the cache logs everyone out or empties every cart, it is
  storage, and gets the durability of storage.

## Testing and observing

- **Tests** run against the real cache in a container (`references/quality/testing.md`) and prove:
  - a write is visible after the invalidation, and the write–read race does not leave the old value;
  - two tenants or users with the same request never see each other's entry;
  - with the cache down, the use case still answers — from the store, within its limits;
  - concurrent misses on one key produce one load.
- **Observe** hits and misses per data set, evictions, size, load reaching the store, and the age of
  served values. A falling hit rate is a leading signal of a capacity problem in the store.

## Left out

- **Memoization within one request or computation** — an ordinary local variable, needing none of the
  above.
- **The ORM's second-level cache and the cache library** — the stack playbook's choice.
- **CDN and proxy configuration** — operations, recorded with the deployment, following the Security
  rules above.
- **Semantic caching of model responses** — research it for the case at hand; it must never return
  one user's answer to another.
