---
layout: default
title: "How the .NET Garbage Collector Works"
date: 2026-08-31 09:00:00 +0000
---

When we talk about memory management in .NET, most developers think about the garbage collector as a background cleanup mechanism. That is true, but it is also incomplete.

From an architect’s perspective, the GC is one of the most important parts of the runtime because it shapes application latency, throughput, memory usage, and even how we design software. From a developer’s perspective, it is the system that decides whether an object is alive or dead, and it does so in a way that is fast, predictable, and surprisingly efficient most of the time.

The real question is not simply “what does the GC do?” but also “what should we understand about it so we can design better systems?”

## The role of the Garbage Collector

In .NET, the runtime manages memory for the managed heap. The garbage collector is responsible for:

- allocating memory for new objects
- finding which objects are still reachable
- reclaiming memory used by objects that are no longer in use
- minimizing fragmentation and keeping the heap healthy
- managing collection across different generations of objects

This happens automatically. You do not manually call `free()` or `delete()`. The runtime tracks object lifetimes for you.

That automatic memory management is a huge productivity win, but it is not magic. It works because .NET uses a root-based model: if an object can be reached from a root, it is considered alive. If it is not reachable, it is eligible for collection.

## Roots and reachability

A GC root is anything the runtime knows can reach object references. Typical examples include:

- local variables on the stack
- static fields in classes
- CPU registers
- GC handles
- objects referenced by other reachable objects

When the garbage collector runs, it starts from those roots and walks the object graph. Every object it can reach is considered live. Everything else is garbage.

This means an object can survive for a long time if it is referenced by a long-lived component, such as a singleton, a static cache, or a service instance. Conversely, short-lived request data or temporary DTOs can die very quickly.

That is why the GC is not just “memory cleanup”; it is a reachability analysis engine.

## The managed heap

In .NET, objects are stored in the managed heap. The heap is not a single flat memory block with no structure. It is organized around object allocation and collection behavior.

The heap is segmented into generations:

- Gen 0
- Gen 1
- Gen 2
- Large Object Heap (LOH)

These generations are an optimization based on a simple but powerful observation:

Most objects die young.

In most real-world applications, a large percentage of allocations are temporary: request-scoped objects, intermediate strings, DTOs, LINQ query results, exceptions, and various intermediate data structures. Those objects often become unreachable quickly. So the runtime optimizes for the common case: quickly reclaiming short-lived objects while keeping long-lived objects out of the way.

## How generations work

The .NET GC uses a generational model because it is much cheaper to collect a small portion of memory frequently than to scan the entire heap each time.

### Gen 0: the nursery

Gen 0 is where new objects are allocated. This is the young generation.

When an object is created, it starts in Gen 0. If it survives a collection, it is promoted to Gen 1. If it survives more collections, it may eventually reach Gen 2.

This is especially effective because most newly created objects are ephemeral. A generation 0 collection is usually fast and inexpensive compared to a full heap collection.

### Gen 1: survivors from the young heap

Gen 1 contains objects that survived one or more Gen 0 collections but are not yet considered long-lived. It represents a middle ground between short-lived and long-lived objects.

### Gen 2: the long-lived heap

Gen 2 is the old generation. Objects that survive long enough end up here. These are usually the objects that live for the entire application lifetime or the duration of a long-running operation, such as services, caches, static state, or high-level application context.

A Gen 2 collection is more expensive because it deals with a larger portion of memory and often requires more scanning.

### The Large Object Heap

Large objects, typically arrays above a certain threshold, are stored in the Large Object Heap. The LOH is treated differently because large allocations are more expensive to move and compact.

This matters for application design. If you repeatedly allocate large arrays or large strings, you can cause more pressure on the LOH and trigger more expensive collections. This is one of the most common reasons for memory churn in large enterprise systems.

## Why generations work so well

The whole generational idea is built around a very practical principle:

- most objects die young
- frequent, focused collection of young objects is cheap
- long-lived objects are uncommon and therefore less frequently collected

This design reduces the cost of garbage collection dramatically. A Gen 0 collection can be done many times without hurting throughput too much. Full heap collections become a rarer and more expensive event.

From an architect’s perspective, this is a critical performance optimization. It lets the runtime assume that object lifetimes are usually short, which matches the patterns of modern software development.

## Allocation patterns and why they matter

One of the most important things to understand is that the GC is sensitive to allocation patterns.

### Allocation is cheap, but churn is expensive

Allocating a small object is cheap. The runtime can do it very fast. But if your code allocates thousands or millions of objects per second, the GC will have to work harder. More allocations mean more pressure on Gen 0, more promotions, more memory traffic, and potentially more Gen 2 collections if objects survive too long.

This is often where architecture and developer choices collide.

### Temporary objects are normal

Applications create many temporary objects. That is expected. The issue is not “allocating” itself; it is excessive allocation combined with long object lifetimes or large object creation rates.

Typical examples include:

- LINQ query materialization
- repeated string concatenation
- creating DTOs for each request
- logging objects with expensive formatting
- high-frequency event handlers capturing lambdas and closures
- large arrays created in loops

A proper architecture should be aware of which code paths are hot and allocate heavily.

### Object retention matters too

A major source of memory pressure is not only allocation rate but also retention. If objects survive longer than expected, they can accumulate and fill the heap.

This happens when:

- static caches grow without bounds
- service containers keep references alive for too long
- event subscriptions are never unsubscribed
- large object graphs remain rooted by long-lived application state

This is where an architect needs to think beyond micro-optimization. System design decisions determine the shape of the heap.

## Memory allocation patterns in practice

From a developer’s point of view, allocation patterns are often the first thing that becomes obvious during profiling.

### Short-lived data

This is the most common and healthiest pattern. Request-scoped objects, local variables, and temporary DTOs are ideal for Gen 0. They are collected quickly and do not create long-term pressure.

### Long-lived state

This is where memory usage needs to be controlled carefully. Singletons, caches, and shared services can hold references indefinitely. If a cache or collection grows unbounded, the GC cannot reclaim it, and your application starts to consume more memory over time.

### Large arrays and buffers

Large allocations are expensive because they hit the LOH and are harder to compact. Repeated large allocations can create fragmentation and can worsen the performance of collection cycles.

### Boxing and value-type churn

Boxing a value type creates a heap object. If the code boxes frequently in a tight loop, it creates significant allocation pressure. This often shows up with generic collections, non-generic APIs, and repeated conversions from `int`, `struct`, or enums into `object`.

For performance-sensitive code, avoiding unnecessary boxing is a real optimization.

## What happens during a collection

The GC does more than simply look for unreachable objects. It goes through collection phases.

### Mark phase

The runtime finds all reachable objects by traversing the roots and the object graph. Reachable objects are marked as live.

### Sweep phase

Unreachable objects are reclaimed. Their memory is made available for future allocations.

### Compacting phase

In some collection modes, the runtime may move surviving objects to reduce fragmentation. Compaction helps maintain a healthier heap and can improve locality.

The exact steps depend on runtime configuration and the generation being collected, but the core idea is the same: identify live objects and reclaim dead ones efficiently.

## The architect’s perspective

From an architectural standpoint, the GC is not a nuisance; it is part of the runtime contract.

If you design a system that constantly creates short-lived objects but is also memory-bound, the GC will be a central part of your performance story. If you design a system with long-lived caches, large graphs, and object retention, the GC will become more of a memory management challenge.

A good architect thinks about:

- object lifetime boundaries
- cache size and expiry policies
- request processing lifecycle
- concurrency and thread-local work
- memory footprint in both steady state and burst conditions

The architecture should minimize avoidable allocations and keep object lifetimes aligned with the real business needs of the system.

## How to reduce memory consumption in .NET

The best way to think about memory reduction is not “turn off the GC” but “make the GC do less work.”

### 1. Reduce unnecessary allocations

This is the highest-impact improvement. Avoid creating objects you do not need. In a hot path, a small allocation pattern can become a major problem.

Examples:

- avoid string concatenation in loops
- avoid repeated LINQ operations on large sequences when the result is not needed
- avoid creating large DTOs in hot paths
- prefer reusable objects or cached results when appropriate

### 2. Use pooling for high-frequency objects

For objects that are frequently created and disposed, object pooling can help. This is especially useful for buffers, network message objects, or other reusable structures.

The .NET runtime already provides some of this support through `ArrayPool<T>`, which is a good option for reusable buffers.

### 3. Use `using` and dispose patterns correctly

The GC does not manage unmanaged resources. If you allocate resources like file handles, sockets, database connections, or unmanaged memory, you must dispose them properly.

Failure to do so can lead to memory leaks, resource starvation, and large GC pressure caused by lingering objects that keep unmanaged resources alive.

### 4. Watch for large object allocations

Large arrays and large strings can put pressure on the LOH. If you process large payloads or build large in-memory structures, consider batching, streaming, or using more efficient data structures.

### 5. Avoid capturing state unnecessarily

Closures and lambdas often create hidden allocations. If a lambda captures a lot of state or is created repeatedly, it can create memory pressure that is hard to see at first glance.

### 6. Prefer value types when they make sense

Value types can reduce heap allocation, but they are not always the right choice. Use them carefully in hot paths, especially for small immutable data models or struct-based algorithms, while avoiding excessive copying or large stack-heavy operations.

### 7. Measure before optimizing

The most useful optimization is the one based on evidence. Use profiling tools to inspect:

- allocation rate
- Gen 0 collection frequency
- Gen 2 collection pressure
- LOH usage
- object retention

Tools like dotnet-trace, dotnet-counters, dotnet-gcdump, and Visual Studio’s memory profiler all help answer the real questions: what is being allocated, what is surviving, and what is causing the heap to grow.

## A practical mental model

The easiest way to reason about the GC is this:

- the runtime gives you memory by allocation
- the runtime decides if objects are still alive by following roots
- short-lived objects are collected cheaply in Gen 0
- long-lived objects move into older generations
- memory pressure is a design issue, not only a runtime issue

If you keep object lifetimes short and avoid unnecessary retention, the GC remains efficient and predictable. If you create too many long-lived objects or large graphs, the GC becomes a bottleneck and memory usage grows.

## Final thoughts

The garbage collector is one of the most important parts of the .NET runtime, but it is not a blanket excuse for poor memory design. It is a powerful system that does a lot of work for us, but it still depends on how we allocate, retain, and release objects.

From a developer perspective, understanding generations helps you write better-performing code. From an architect’s perspective, understanding object lifetime and allocation patterns helps you design systems that remain stable under load, do not leak memory, and scale with predictable costs.

A healthy .NET application is not one that avoids memory management entirely. It is one that respects the runtime’s assumptions and builds code around the natural lifecycle of objects.

That is the real lesson: the GC is not a replacement for sound design. It is a mechanism that rewards good design and punishes careless retention.
