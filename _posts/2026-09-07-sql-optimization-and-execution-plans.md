---
layout: default
title: "SQL Optimization and Execution Plans in .NET Applications"
date: 2026-09-09 10:00:00 +0000
---

# SQL Optimization and Execution Plans in .NET Applications

Most application developers know the idea of performance tuning, but SQL optimization is often treated as a database-only concern. In .NET applications, this is a common misunderstanding.

The query shape emitted by the application has direct consequences on CPU usage, memory usage, latency, and scalability. A single inefficient query can create a bottleneck that affects the entire system, even if the application code itself is well designed.

When you use Entity Framework, ADO.NET, or other data access layers, the application is not “just calling the database.” It is sending SQL statements that the database must interpret and execute. If the query is poorly shaped, the database will do more work than necessary. The result is slow response times, high I/O, table scans, increased lock contention, and reduced throughput.

The real solution is not to guess. It is to inspect the execution plan and adjust the query and indexes around real evidence.

## What an execution plan shows

An execution plan is the database engine’s blueprint for how it intends to run a query.

It shows things like:

- whether the database will do a table scan or an index seek
- how joins are being executed
- whether sort operations are required
- whether the engine expects many rows or few rows
- whether key lookups are happening
- how much work the database estimates before execution

The plan is not just a technical artifact. It is a map of the query’s cost profile. It tells you where the database is spending effort and where the poor design is hiding.

For example, a query that performs a full table scan for every request may look harmless in the application code, but under load it can easily become a serious bottleneck. In contrast, a well-optimized query may be able to read only a small subset of rows using an index and avoid expensive disk or memory operations.

## How SQL stores and accesses data internally

To understand execution plans deeply, you need to know how the database physically stores data.

SQL database engines like SQL Server organize table data into structures called **pages**. A page is typically an 8 KB chunk of disk or memory that contains multiple rows. When you query a table without an index, the database engine must scan from the first page through all pages sequentially, reading every row to find matches. This is a **table scan** or **heap scan**.

The data in a heap (unindexed table) is stored in the order it was inserted, with no inherent structure. The engine maintains no roadmap to locate specific rows, so it must read every page.

In contrast, **indexes** create a hierarchical structure that enables fast navigation. Most indexes use a B-tree structure: a tree of index pages where internal nodes point to child nodes and leaf nodes contain pointers to actual data rows. This structure is critical to understanding why an index seek is so much cheaper than a table scan.

When the database performs an **index seek**, it navigates down the B-tree using the search criteria to locate the exact leaf page that contains matching rows. It then reads only that page (or a small set of pages). This is orders of magnitude faster than reading every page in the table.

A **table scan** reads the entire table sequentially from disk into the buffer pool. For a large table, this can mean thousands or millions of page reads. A **seek** might read only a handful of pages.

This page-based model is fundamental to SQL optimization: every query cost is ultimately measured in I/O operations, CPU cycles used to process rows, and memory used to cache pages in the buffer pool.

## Reading the plan: scans, seeks, joins, and estimates

The most common signs of a problematic plan include:

- table scans on large tables
- high estimated row counts
- nested loops over large datasets
- sort operations without a suitable index
- key lookups after index seeks
- hash joins or merge joins that are unnecessary for the actual data shape
- repeated full scans for similar lookup patterns

### Scans and seeks

A table scan is not automatically a bug, but it becomes suspicious when the table is large and the query is selective. A seek is far more efficient when the database can use an index to locate exact rows.

The difference is structural: a scan must visit every page, while a seek uses the B-tree to navigate directly to the relevant pages. For a table with 1 million rows stored across 10,000 pages, a scan might read 10,000 pages. A seek might read 3-5 pages (the depth of the B-tree plus leaf pages with matching rows).

However, scans are the right choice when the query returns a large proportion of the table. If a query selects 50% of rows, the overhead of seeking through the index tree might exceed the cost of simply scanning the table.

### Key lookups and RID lookups

A common optimization issue is the **key lookup** (in clustered indexes) or **RID lookup** (in heaps). This happens when:

1. The optimizer finds matching rows using a non-clustered index.
2. But the index doesn't contain all the columns the query needs (it's not a covering index).
3. So for each matching row, the database must jump to the clustered index or heap to fetch the full row.

If a non-clustered index scan returns 10,000 qualifying rows, but each requires a key lookup to get missing columns, the query performs 10,000 additional random I/O operations. This can be far more expensive than a single table scan.

This is why **covering indexes** matter: an index that includes all columns needed by the query eliminates lookups.

### Join strategies

A join is not inherently expensive, but the join strategy matters. The database optimizer chooses between three main join algorithms, each with different cost profiles:

**Nested Loop Join**: The outer input is iterated once, and for each row, the inner input is searched. This is efficient when:
- The outer input is small (few rows).
- The inner input has a good index on the join column.

But nested loops over large datasets become expensive quickly, requiring many index seeks or scans of the inner table.

**Hash Join**: Both inputs are read, and a hash table is built from the smaller input. The larger input is probed against the hash table. This is efficient when:
- Both inputs are moderate-to-large.
- No index exists on the join column.
- Memory is available to hold the hash table.

The trade-off is memory usage and the cost of building and probing the hash table.

**Merge Join**: Both inputs are sorted by the join column (either by pre-existing indexes or by sort operations), and the rows are merged together. This is efficient when:
- Both inputs are naturally sorted (matching indexes exist).
- The result set will also be sorted (no additional sort needed).

The trade-off is the sort cost if indexes don't exist.

The optimizer chooses based on estimated row counts and available statistics. A poor join strategy often indicates that the table statistics are stale, the indexes don't support the join pattern, or the query shape is unnecessarily complex.

## Index structures and design trade-offs

Indexes are one of the most important tools for improving query performance, but they are not free.

### B-tree structure and leaf pages

A non-clustered index in SQL Server is a B-tree structure where leaf pages contain the index key columns plus a pointer to the data (either a clustered key or a row identifier). When you create an index on `CustomerId`, all distinct `CustomerId` values are organized in a sorted B-tree. The leaf pages are linked in order, which enables efficient range scans (e.g., `WHERE CustomerId BETWEEN 100 AND 200`).

A **clustered index** is special: its leaf pages ARE the data pages themselves. This means a seek through a clustered index is equivalent to navigating directly to the data. A table can have only one clustered index (usually on the primary key), so every non-clustered index must eventually navigate to either the clustered index or the heap to fetch columns not in the index.

### Trade-offs of indexing strategies

An index helps the database find rows quickly, but it also adds costs:

**Write overhead**: Every INSERT, UPDATE, or DELETE on the table must update every index on that table. A table with 5 indexes has 5x the write cost compared to a table with 1 index. For heavily-written tables, this can become a serious bottleneck.

**Storage overhead**: Each index consumes disk space. A large table with many indexes can consume several times more space than the base table.

**Maintenance cost**: The database engine must periodically rebuild indexes to reorganize fragmented pages, which locks tables and consumes I/O.

**Memory cost**: Indexes consume buffer pool memory, competing with data pages for cache space.

Typical index tuning decisions balance these costs against read performance:

- **Covering indexes**: Include non-key columns in the index to avoid key lookups. This makes the index larger but eliminates random I/O for lookups.
- **Composite indexes**: Place filter columns first, then sort columns (e.g., `(CustomerId, CreatedAt DESC)`). This can satisfy both the WHERE and ORDER BY in a single index navigation.
- **Filtered indexes**: Create indexes only on a subset of rows (e.g., only active orders). This reduces size and maintenance cost while supporting specific query patterns.
- **Partial indexes**: If a column is NULL in most rows, exclude those rows from the index to reduce size.
- **Key ordering**: In a composite index, the order of columns matters. Leading columns are used for filtering, trailing columns for sorting. The wrong order can cause sort operations even with an index present.

### Index fragmentation and scan efficiency

As rows are inserted and deleted, index pages become fragmented (out of sequential order on disk). A fragmented index requires more page reads to scan because pages are not contiguous on disk. The SQL engine must perform more random I/O to fetch non-adjacent pages.

When a B-tree leaf level is fragmented, a range scan that logically reads 1,000 contiguous rows might require 50+ random disk reads instead of a few sequential reads. This is why index maintenance (rebuilds and reorganization) is important for scan-heavy workloads.

### Index statistics and optimizer decisions

The query optimizer uses statistics to estimate the cost of different execution plans. Statistics on indexed columns track the distribution of values (e.g., how many rows have `CustomerId = 42`?). If statistics are stale, the optimizer may choose a poor plan.

For example, if statistics say `CustomerId = 42` matches 100,000 rows out of 1,000,000, the optimizer might choose a table scan. But if `CustomerId = 42` now matches only 10 rows (and statistics are stale), the optimizer should have chosen an index seek. The stale statistics lead to a much slower plan.

## Projections, join planning, and cardinality estimation

When a query selects more columns than the application actually needs, the database has to read more data and often more pages. This can create unnecessary I/O and memory pressure. Every additional column increases the row size, which means fewer rows fit in a page, which means more pages must be read to retrieve the same logical number of rows.

The same applies to joins. A join is necessary when the data is cross-related, but unnecessary joins or poor join order can explode cost. In many cases, the right optimization is to reduce the amount of data early in the query and only join the data that is truly needed.

### Cardinality estimation and join order

The query optimizer must decide the order in which to join tables. If a query joins `Orders`, `Customers`, and `OrderItems`, the join order dramatically affects performance.

If the optimizer joins `Orders` to `Customers` first (resulting in 1M rows) and then to `OrderItems` (resulting in 5M rows), the nested loop will be expensive. But if it first joins `Orders` to `OrderItems` (staying at 1M rows) and then to `Customers`, the final loop might be much cheaper.

The optimizer uses cardinality estimation (the estimated number of rows at each stage) to make this decision. If cardinality estimates are wrong (due to stale statistics or poor column distributions), it may join in the wrong order.

### Application design and SQL generation

This is also a place where application design influences SQL performance. If a .NET service loads a large entity graph using Entity Framework without proper filtering (e.g., `.Include(o => o.Items).Include(o => o.Customer)`), it can generate a query that joins many tables and returns far more data than needed.

In many cases, the right solution is to use projection queries instead:

```csharp
// Bad: returns full entity graph, maybe unnecessary columns
var order = await context.Orders
    .Include(o => o.Items)
    .Include(o => o.Customer)
    .FirstOrDefaultAsync(o => o.Id == orderId);

// Better: projects only needed columns
var orderSummary = await context.Orders
    .Where(o => o.Id == orderId)
    .Select(o => new {
        o.Id,
        o.OrderDate,
        CustomerName = o.Customer.Name,
        ItemCount = o.Items.Count()
    })
    .FirstOrDefaultAsync();
```

The second query is not only more efficient SQL, but also reduces serialization overhead and memory usage in the application.

## Parameter sniffing and plan reuse

A subtle but common issue in production is **parameter sniffing**. When a parameterized query like `SELECT * FROM Orders WHERE CustomerId = @customerId` is first compiled, the optimizer generates a plan based on the parameter value provided at compile time.

If the first execution uses `@customerId = 1` (which has 100,000 associated orders), the optimizer generates a plan optimized for a large result set (maybe a table scan or hash join).

On the next execution with `@customerId = 999` (which has only 5 associated orders), the compiled plan is reused, but it's now sub-optimal. The plan expects 100,000 rows but only gets 5. Sorts, joins, and memory allocations are all sized for the wrong cardinality.

In high-concurrency systems, parameter sniffing can cause random performance spikes: the same query runs fast for some customers and slow for others, depending on which parameter value was used to compile the plan.

Solutions include:

- **Recompiling on each execution**: `OPTION (RECOMPILE)` in SQL, though this has a CPU cost.
- **Using query hints**: Providing explicit optimizer hints that work across parameter values.
- **Improving statistics**: Ensuring histograms capture column value distributions.
- **Breaking the query**: Sometimes splitting one parameterized query into multiple simpler queries avoids the problem.

## Memory, buffer pool, and access patterns

SQL Server and other databases cache frequently-accessed pages in the **buffer pool**, a pool of in-memory pages that live in RAM. When a query hits a page in the buffer pool, it's as cheap as a memory read. When it misses (a cache miss), the engine must fetch from disk, which is orders of magnitude slower.

Good query design minimizes cache misses by accessing data sequentially where possible. A B-tree index scan of contiguous leaf pages has good locality of reference: each page read likely brings into cache the next pages needed. A query that requires random I/O to scattered pages misses the cache frequently.

This is why:
- **Index fragmentation matters**: Fragmented indexes cause random I/O even though the index structure is correct.
- **Clustered index design matters**: A good clustered index orders data in a way that matches common query patterns. If queries typically search by date range, clustering by date is efficient.
- **Table width matters**: Wide rows (many columns) mean fewer rows per page, which means more pages to read for the same logical data.

The buffer pool is also shared across all databases and workloads on a server. A long-running report that scans a huge table can evict frequently-used pages from the buffer pool, slowing down other queries. This kind of resource contention is often invisible in isolated testing but critical in production.

## A practical example: index design and execution plans

Consider a query that filters on a non-indexed column and then sorts the result set:

```sql
SELECT *
FROM Orders
WHERE CustomerId = 42
ORDER BY CreatedAt DESC;
```

Without an index, the optimizer must perform a **table scan** (read every page of the Orders table) and then a **sort** operation to order the results. For a table with 1M orders and 1M pages, this means:
- 1M page reads to scan the table.
- Temporary storage allocation for the sort (and possibly spilling to disk).
- High CPU to compare and sort rows.

The execution plan might show a Sort operator with an estimated cost of 40% of the query.

Now add an index on the filter and sort columns:

```sql
CREATE INDEX IX_Orders_CustomerId_CreatedAt
ON Orders (CustomerId, CreatedAt DESC)
INCLUDE (/* other columns the query needs */);
```

This composite index changes everything. The optimizer can now:
1. **Seek** to the index pages where `CustomerId = 42` (not a scan).
2. Navigate the B-tree to find the first matching entry.
3. Scan forward through the leaf pages (which are already sorted by `CreatedAt DESC` due to the index definition).
4. Collect all matching rows without a separate sort operation.

The new plan is:
- Index Seek on `IX_Orders_CustomerId_CreatedAt` (maybe 5-10 page reads instead of 1M).
- No sort needed.
- If the index is a covering index (includes all needed columns), no key lookups.

The cost drops from seconds to milliseconds.

### Why index column order matters

Notice the index definition: `(CustomerId, CreatedAt DESC)`. The order is critical:

- **Leading column (CustomerId)**: Used for the WHERE predicate. The optimizer can seek directly to this value.
- **Trailing column (CreatedAt DESC)**: Used for the sort and already in descending order in the index.

If the index were defined as `(CreatedAt DESC, CustomerId)`, the optimizer could not seek by CustomerId first. It would have to scan the entire index looking for matching CustomerId values.

### Covering index considerations

The INCLUDE clause adds non-key columns to the index leaf pages without including them in the B-tree structure. This eliminates key lookups but increases index size. A covering index on a wide table (many columns) can be nearly as large as the table itself.

The decision to cover depends on:
- **Query selectivity**: If the query often returns many columns, covering is worthwhile.
- **Write patterns**: If the table is heavily written, the extra index maintenance cost matters.
- **Storage**: If space is constrained, you may accept key lookups instead.

In EF Core, the same idea often appears as:

```csharp
var recentOrders = await context.Orders
    .Where(o => o.CustomerId == customerId)
    .OrderByDescending(o => o.CreatedAt)
    .Take(50)
    .ToListAsync();
```

This LINQ query generates the SQL above. The resulting execution plan is efficient if the right index exists.

## Reading execution plans and understanding costs

Execution plans in SQL Server can be viewed as graphical trees or XML. The key metrics to understand are:

**I/O Cost**: The estimated number of page reads. A seek costs 2-5 I/O, a scan costs thousands or millions. The optimizer uses I/O cost as the primary optimization metric.

**CPU Cost**: The estimated CPU cycles to process rows. Sorts, hash joins, and other operations are CPU-intensive.

**Row Count Estimate**: The number of rows the optimizer expects at each stage. If the estimate is wildly wrong (e.g., estimates 100 rows but gets 1M), the plan was likely generated under parameter sniffing or stale statistics.

**Actual vs. Estimated**: When you run a query with "Include Actual Execution Plan", SSMS shows both estimated (planned) and actual (observed) row counts. Large discrepancies indicate bad statistics or parameter sniffing.

**Operators to watch**:
- `Table Scan`: Linear scan of entire table. Acceptable for small tables or queries returning most rows.
- `Index Seek`: Efficient navigation using B-tree. This is what you want.
- `Key Lookup` or `RID Lookup`: Random lookups to fetch missing columns. Expensive if done thousands of times. Look for covering indexes to eliminate these.
- `Sort`: Often expensive, especially on large sets. If sorting is required, seek an index that provides that order.
- `Hash Aggregate` or `Stream Aggregate`: Group/aggregate operations. Hash is good for unsorted data, stream is good when data is already sorted.
- `Nested Loops`: OK for small outer inputs and indexed inner inputs. Bad for large outer inputs or non-indexed inner tables.
- `Hash Join`: Good for large unsorted inputs, but requires memory and CPU for hash table.

## SQL Profiler, extended events, and tracing

If you cannot see the SQL, you cannot diagnose it well.

Tools such as SQL Server Profiler (legacy), Extended Events, Query Store, and database logs help capture slow or expensive queries. They let teams answer questions like:

- which queries are running slowly?
- which statements are consuming the most CPU or I/O?
- which operations are blocking others?
- are there surprising spikes in query duration during specific workloads?
- how often does each query run, and what is its average duration?

### Query Store (modern best practice)

SQL Server 2016+ includes **Query Store**, which captures actual runtime metrics without the overhead of Profiler. It tracks:
- Execution count and duration for each query.
- Memory and I/O consumed.
- Plan changes and which plans are fastest.

Query Store is always-on and has minimal performance impact. It can answer questions like "did plan for query X change between version 1 and 2?"

### Extended Events (for detailed tracing)

Extended Events is the modern replacement for SQL Profiler. It's lower-overhead and can capture SQL statements, execution plans, blocking events, and deadlocks. For .NET applications, capturing both the SQL statement and the application context (e.g., correlation ID or user ID) enables correlation during diagnosis.

### Application-level correlation

For .NET teams, capturing and correlating query traces with application logs is often the fastest route to root cause analysis. By logging correlation IDs in both the application and in SQL tracing, you can connect a slow endpoint to a specific SQL statement and even to a specific call path in code.

For example:
```csharp
using (var activity = Activity.StartActivity("FetchOrders"))
{
    var correlationId = activity?.Id ?? Guid.NewGuid().ToString();
    
    // Pass correlation ID to SQL via session context or logging
    using (var connection = new SqlConnection(connectionString))
    {
        connection.Open();
        using (var cmd = connection.CreateCommand())
        {
            cmd.CommandText = $"EXEC sp_set_session_context @key = 'CorrelationId', @value = '{correlationId}'";
            cmd.ExecuteNonQuery();
        }
        
        // Now run queries; the correlation ID is available in Extended Events
        var orders = await context.Orders.ToListAsync();
    }
}
```

When an Extended Events trace captures this query, it includes the correlation ID, making it easy to match with application logs.

## Diagnosing slow queries in production

Slow queries in production are not always caused by a single bad index. They may result from a combination of factors:

- **Parameter sniffing issues**: A query compiles with one parameter value but executes with another, using a sub-optimal plan.
- **Missing or poorly ordered indexes**: The right index doesn't exist, or index column order doesn't match the query pattern.
- **Poor join strategies**: The optimizer chose a nested loop instead of a hash join, or vice versa.
- **Outdated statistics**: The optimizer makes decisions based on stale distribution statistics, leading to poor cardinality estimates.
- **Lock contention and blocking**: Queries wait for locks held by other transactions. The query itself is fast, but concurrency is the bottleneck.
- **Blocking from concurrent transactions**: One query holds locks on resources that others need. Examining `sys.dm_exec_requests` and `sys.dm_exec_sessions` reveals which sessions are blocking whom.
- **Heavy reporting workloads during business hours**: A large analytical query evicts frequently-used pages from the buffer pool, causing cache misses for OLTP queries.

### Diagnosing locking and blocking

In SQL Server, you can query dynamic management views (DMVs) to understand contention:

```sql
-- Find blocking sessions
SELECT 
    blocking_session_id,
    session_id,
    status,
    last_request_start_time,
    last_request_end_time
FROM sys.dm_exec_sessions
WHERE blocking_session_id > 0;

-- See what the blocking session is doing
SELECT * FROM sys.dm_exec_requests
WHERE session_id = @blocking_session_id;
```

Common causes of blocking include:

- **Long-running transactions**: A transaction holds locks for too long. Solutions: shorter transactions, better isolation levels, row-level locking.
- **Lock escalation**: Many row locks are held, so the engine escalates to table locks, blocking other queries. This can happen when an UPDATE or DELETE touches many rows.
- **Deadlocks**: Two sessions lock resources in opposite order, creating a cycle. SQL Server detects this and kills the "victim" transaction.

### Waits and latching

SQL Server also tracks **wait types** through `sys.dm_os_waiting_tasks` and `sys.dm_exec_session_wait_stats`. Wait times reveal where time is actually spent:

- `PAGEIOLATCH_*`: Waiting for page reads from disk (I/O-bound).
- `LOCK_*`: Waiting for locks held by other sessions (lock contention).
- `LOGBUFFER`: Waiting for log buffer space (too much write load).
- `THREADPOOL`: Waiting for available threads (CPU starvation).

If a query shows high `PAGEIOLATCH` waits, the problem is I/O (add indexes or improve query selectivity). If it shows high `LOCK` waits, the problem is contention (shorten transactions, improve isolation).

### Workload analysis and resource governor

In production, a single slow query might be masking a larger problem: an uncontrolled workload starving the system. A long-running reporting query might consume 90% of CPU and I/O, leaving only 10% for transactional queries.

Solutions include:

- **Query timeout policies**: Set aggressive timeouts on long-running queries.
- **Resource Governor**: Limit CPU, memory, and I/O per workload or user.
- **Workload segregation**: Run analytical queries on a separate replica or time-windowed batch jobs during off-peak hours.
- **Connection pooling tuning**: Ensure the application doesn't leak connections or exhaust the pool.

## Query performance and code review culture

One of the highest-return engineering practices is to treat database queries as part of code review.

Developers should ask:

- Is this query expensive in the worst-case scenario?
- Are we selecting more data than needed?
- Is the query stable under larger datasets?
- Are there missing indexes or poor join patterns?
- Are we creating unnecessary full scans?
- Does the application read the same data repeatedly?

This is especially important in .NET applications that use ORMs. They can hide complexity and make a query appear simple when it is actually doing a lot of work.

## EF and SQL tuning go together

Entity Framework is often blamed for poor query performance, but in many cases the issue is not EF itself. The issue is that the generated LINQ query is not aligned with the database design or workload.

This is why EF performance work often involves both:

- adjusting the LINQ shape to create better SQL
- tuning the physical database design to support the workload

For example, a query that uses a large `Where` clause with a non-indexed property may create a slow scan. But if the correct index is added, the execution plan may change drastically and the latency may drop.

## A practical tuning workflow

When a performance issue is suspected, a strong workflow looks like this:

1. **Capture the actual query in the target environment**: Use Query Store, Extended Events, or application logging to get the exact SQL and execution plan.

2. **Inspect the execution plan**: Load the plan XML into SSMS or a plan analysis tool. Identify expensive operators (scans, sorts, key lookups, hash joins).

3. **Check actual vs. estimated row counts**: If estimates are way off, the issue is statistics. Update statistics on key columns.

4. **Identify expensive operations and their cost drivers**:
   - Is a table scan happening on a large table? Look for an index opportunity.
   - Are key lookups happening repeatedly? Consider a covering index.
   - Is a sort operation expensive? Look for an index that provides that order.
   - Is a hash join happening with huge memory usage? Investigate join selectivity and cardinality.

5. **Examine index usage**: Check if suitable indexes exist. Use DMVs like `sys.dm_db_index_usage_stats` to see which indexes are used.

6. **Reduce the data set before joins or sorts**: Apply WHERE filters early to reduce rows flowing through downstream operators.

7. **Create or adjust indexes**:
   - Test the index creation plan (estimated cost should decrease).
   - Monitor write performance (indexes add insertion/update cost).
   - Verify index selectivity: Check that queries actually use the new index.

8. **Validate the change with real workload tests**: Run the modified query against realistic data and concurrency levels. Measure CPU, I/O, memory, and latency.

9. **Test in staging before production**: Index creation and query changes can have unexpected side effects. Staging validation is crucial.

10. **Keep monitoring after deployment**: New workload patterns may emerge. Use Query Store to track performance over time and detect regressions.

### Advanced tuning techniques

**Query hints**: In some cases, the optimizer chooses a sub-optimal plan. You can force a better plan using hints:
```sql
SELECT * FROM Orders
WHERE CustomerId = 42
OPTION (FORCE ORDER, LOOP JOIN);  -- Forces nested loop join in specific order
```

Use hints sparingly (they won't benefit from optimizer improvements in future versions) and only when you have evidence they help.

**Explicit statistics updates**: If statistics are stale:
```sql
UPDATE STATISTICS Orders ON (CustomerId);
```

**Isolation level tuning**: Lower isolation levels (READ COMMITTED) reduce lock duration compared to higher levels (REPEATABLE READ, SERIALIZABLE). The trade-off is potential consistency issues.

**Rewrite and refactor**: Sometimes the right fix is to rewrite the query entirely. Break it into smaller, simpler pieces or use different joins.

## Final thoughts

SQL optimization is not a side topic in .NET development. It is part of building reliable, scalable software.

When developers understand execution plans and database behavior, they can make better decisions about indexes, projections, joins, and query structure. That leads to lower latency, less resource consumption, and more predictable application behavior.

The real lesson is simple: the database engine is not a black box. Every query has a plan, and every plan has a cost. If you want to optimize .NET applications, you need to understand the cost of the SQL that they emit.
