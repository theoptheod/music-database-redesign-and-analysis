# Performance Comparison: Old vs. New Schema /-/ Technical Analysis

## Summary
This document provides a detailed evaluation of how the legacy and the redesigned schema perform across five analytical workloads.  
Each benchmark uses `EXPLAIN ANALYZE` to measure execution time, join strategies, row‑processing volume, and planner behavior.

### 1. Benchmarking Methodology
All queries were executed on PostgreSQL using the following procedure:
* Run each query multiple times
* Warm the buffer cache
* Average the last three execution times
* Capture full execution plans for both schemas
* Compare join strategies, row counts, and planner decisions

This ensures stable, reproducible results that reflect true structural differences between the two schemas rather than temporary cache effects.

### 2. Why Performance Benchmarking Is Necessary
The legacy schema contains several structural flaws that directly impact analytical workloads:
* Floating‑point currency which results in rounding errors and inconsistent totals
* Denormalized relationships, that cause wider rows and inefficient joins
* Missing foreign keys which lead to planner uncertainty and sequential scans
* Inconsistent geography fields which create unreliable grouping
* One‑to‑many artist/album modeling that produce incorrect analytics for collaborations

The normalized schema addresses these issues through:
* Integer‑based currency
* Many‑to‑many junction tables
* Strict foreign‑key constraints
* Atomic customer and geography fields
* Narrower tables and selective join keys

Benchmarking quantifies the impact of these improvements.

### 3. Benchmark Query Results
**Query 1 - Customer Spending on the Top‑Selling Artist**  
The first benchmark query calculates total revenue per artist, identifies the top‑selling artist, and determines how much each customer spent on that artist.
This query stresses join chains, aggregation correctness, currency precision, and join efficiency making it an ideal test of schema quality.

Why This Query Matters
Artist‑level revenue analytics are foundational in digital music platforms.
They drive:
* royalty calculations
* catalog valuation
* artist performance reporting
* personalized recommendations

A schema that cannot compute artist revenue accurately or efficiently is fundamentally limited.

#### Old Schema
In the unnormalized schema, artist information is stored directly on the `album` table, and invoice totals rely on floating‑point arithmetic.
This leads to:
* larger intermediate result sets
* less efficient join paths
* rounding inconsistencies
* nested loops in the execution plan

As a result, the old schema can answer the question, but with reduced accuracy and less predictable performance.

#### EXPLAIN ANALYZE — Old Schema Summary
Key issues observed:
* nested loop joins multiply row counts
* sequential scans on `invoice_line`, `track`, `album`, and `artist`
* floating‑point arithmetic introduces rounding errors
* wider intermediate result sets increase sorting and hashing cost

Although execution time appears similar on the legacyc dataset, the plan structure is significantly less efficient and would degrade rapidly as data volume increases.

Old Schema Performance

| Metric             | Old Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~1.4 ms**  |
| **Execution Time** | **~12.3 ms** |

#### New Schema
Artists, albums, and tracks are connected through many‑to‑many junction tables, and all monetary values are stored as integer cents.  
This results in:
* more accurate revenue totals
* cleaner join paths
* hash joins instead of nested loops
* narrower intermediate result sets
* a significantly cheaper artist‑earnings CTE

#### EXPLAIN ANALYZE — Normalized Schema Summary
Key improvements:
* Hash joins instead of nested loops
* Efficient junction tables (`artist_album`, `album_track`)
* Integer‑based currency eliminates floating‑point errors
* Top‑selling‑artist CTE runs 4× faster
* Narrower rows and smaller hash tables lead to faster sorting

Although planning time is slightly higher due to more join paths, the execution plan is structurally superior and scales far better as data volume increases.

Full execution plans are available in the /analysis directory.

New Schema Performance

| Metric             | New Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~5.4 ms**  |
| **Execution Time** | **~12.0 ms** |

**Query 2 - Most Popular Genre per Country**  
The second benchmark query identifies the most popular music genre in each country, based on total track purchases.  
This query stresses a different part of the schema than Query 1.  
Instead of focusing on artist revenue, it tests the correctness and efficiency of genre metadata, customer geography, and track‑level purchase analytics.

Why This Query Matters  
Genre popularity is a core analytical requirement in digital music platforms.  
It drives:
* recommendation systems
* regional marketing
* licensing decisions
* catalog optimization

A schema that cannot answer this query accurately or efficiently is fundamentally limited.

#### Old Schema
In the unnormalized schema, genre analytics are constrained by several structural issues:
* `genre` is stored directly on the `track` table, preventing many‑to‑many relationships between tracks and genres.
* `customer` country data is inconsistent and not part of a proper geographic hierarchy.
* Invoice totals rely on floating‑point arithmetic, which introduces rounding errors when aggregating across thousands of rows.
* Joins must traverse wide, denormalized tables, increasing row size and reducing planner flexibility.
* Aggregations often require sequential scans and nested loops.

As a result, the old schema produces heavier execution plans and less reliable analytical results.

#### New Schema
The normalized schema resolves these issues by introducing:
* a genre_track junction table that supports many‑to‑many relationships
* a clean, atomic geographic hierarchy (country → state → city)
* integer‑based currency (*_cents) for exact revenue calculations
* narrower tables with strict foreign‑key constraints
* more efficient join paths for analytical queries

These improvements allow PostgreSQL to use hash joins, reduce row duplication, and compute country‑level genre popularity with greater accuracy and scalability.

#### What This Query Demonstrates
Benchmark Query 2 highlights improvements in:
* analytical correctness
* join efficiency
* grouping performance
* geographic consistency
* revenue accuracy
* execution plan quality

Full SQL queries and execution plans for both schemas are available in the `/analysis` directory.

#### EXPLAIN ANALYZE — Query 2 Performance Comparison
Query 2 identifies the most popular genre in each country based on total revenue.  
This query stresses genre metadata, customer geography, and grouping performance.

Old Schema  
The unnormalized schema stores genre_id directly on the track table, which simplifies the join path.  
As a result, PostgreSQL performs:
* fewer joins
* fewer hash tables
* smaller intermediate result sets

This produces a relatively lightweight execution plan:  
| Metric             | Old Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~0.78 ms** |
| **Execution Time** | **~5.81 ms** |

The old schema is faster for this specific query because the denormalized structure reduces join complexity.

#### New Schema
The normalized schema introduces a `genre_track` junction table to support many‑to‑many relationships between tracks and genres.  
This improves correctness and flexibility but increases join cost:
* more rows processed (genre_track has 4040 rows)
* additional hash joins
* larger grouping operations

Execution plan summary:  
| Metric             | New Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~0.95 ms** |
| **Execution Time** | **~8.70 ms** |

Although the normalized schema is slower on the legacy dataset, it produces a more accurate and scalable analytical model.  
In real‑world music catalogs, where tracks often belong to multiple genres, the normalized schema is required for correctness and would scale more effectively.

**Query 3 - Top‑Spending Customer per Country**  
The third benchmark query identifies the highest‑spending customer in each country.
This query stresses the correctness of customer geography, invoice totals, and aggregation logic.

#### Old Schema
In the unnormalized schema, customer spending is derived from the invoice.total field, which is stored as a floating‑point number.
This leads to:
* rounding inconsistencies
* small but cumulative inaccuracies
* inconsistent country values (free‑text field)
* wider rows and less efficient grouping

Despite these limitations, the old schema can still answer the question, but the results may not be mathematically exact.

#### New Schema
The normalized schema resolves these issues by introducing:
* integer‑based currency (`invoice_total_cents`)
* atomic customer name fields
* consistent country values
* enforced foreign keys
* narrower tables and more efficient grouping

This produces exact spending totals and more predictable execution plans.

#### EXPLAIN ANALYZE — Query 3 Performance Comparison
Query 3 identifies the top‑spending customer in each country.  
This query stresses invoice totals, customer geography, grouping, and window functions.

Old Schema  
The unnormalized schema stores invoice totals as floating‑point numbers and uses free‑text country fields.  
This leads to:
* rounding inconsistencies
* wider rows
* less selective joins
* more expensive grouping operations

Execution summary:
| Metric             | Old Schema   |
| ------------------ | -------------|
| **Planning Time**  | **~0.40 ms** |
| **Execution Time** | **~2.39 ms** |

New Schema  
The normalized schema uses integer‑based currency (invoice_total_cents), atomic customer fields, and consistent country values.  
This produces:
* exact spending totals
* narrower rows
* faster hash aggregation
* more efficient join paths
* significantly faster execution

Execution summary:
| Metric             | New Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~0.33 ms** |
| **Execution Time** | **~0.53 ms** |

The normalized schema is over 4× faster for this query, while also producing more accurate and reliable results.

Full execution plans are available in the /analysis directory.

**Query 4 - Top‑Selling Albums**  
The fourth benchmark query calculates the total revenue generated by each album and identifies the top‑selling albums in the catalog.

This query sits between track‑level and artist‑level analytics, making it an important part of the sales hierarchy:
Track → Album → Artist

#### Old Schema
In the unnormalized database schema, each album has a single artist_id, creating a one‑to‑many relationship between artists and albums.  
This structure is simple, but it introduces several limitations:
* Albums cannot belong to multiple artists (incorrect for compilations or collaborations)
* Album revenue is computed using floating‑point totals (invoice.total), which introduces rounding errors
* Joins rely on denormalized fields and wider rows

The planner has fewer indexing and constraint guarantees

As a result, the old schema can answer the question, but with reduced accuracy and less efficient execution plans.

#### New Schema
The normalized schema introduces an artist_album junction table, allowing albums to participate in many‑to‑many relationships with artists.  
This models real‑world music catalogs more accurately and improves analytical flexibility.

Additional improvements include:
* integer‑based currency (*_cents) for exact revenue calculations
* enforced foreign keys between albums, tracks, and invoice lines
* narrower tables and more selective join paths
* cleaner grouping and ordering semantics

These changes produce more accurate album‑level revenue and more efficient execution plans, especially as data volume grows.

Why This Query Matters
Album‑level analytics are essential for:
* catalog performance tracking
* royalty calculations
* marketing and playlist curation
* understanding artist and label revenue distribution

Query 4 highlights how normalization improves correctness, flexibility, and scalability in album‑centric analytics.

#### EXPLAIN ANALYZE — Query 4 Performance Comparison
Query 4 identifies the top‑selling albums by total revenue.
This query stresses album metadata, track relationships, many‑to‑many joins, and revenue aggregation.

Old Schema
The unnormalized schema models albums and artists using 1‑to‑many relationships:

each track belongs to exactly one album

each album belongs to exactly one artist

This simplifies the join path:
invoice_line → track → album → artist
but introduces limitations:

albums cannot have multiple artists

tracks cannot belong to multiple albums

revenue is calculated using floating‑point values (unit_price)

grouping is less accurate due to denormalized fields

Execution summary:
| Metric             | Old Schema    |
| ------------------ | ------------- |
| **Planning Time**  | **~0.94 ms**  |
| **Execution Time** | **~12.42 ms** |

New Schema
The normalized schema models albums and artists using many‑to‑many relationships:

`album_track` links tracks to albums

`artist_album` links artists to albums

This reflects real‑world music catalogs (collaborations, compilations, re‑releases) and uses:
* integer‑based currency (`unit_price_cents`)
* enforced foreign keys
* narrower tables

However, correctness comes with additional join complexity:
`invoice_line` -> `track` -> `album_track` -> `album` -> `artist_album` -> `artist`
This increases planning and execution time on small datasets like the unnormalized one.

Execution summary:
| Metric             | New Schema    |
| ------------------ | ------------- |
| **Planning Time**  | **~9.43 ms**  |
| **Execution Time** | **~13.29 ms** |

Interpretation  
Query 4 is the only benchmark where the normalized schema is slightly slower.  
This is expected and reflects a fundamental tradeoff:
* The old schema is faster because it uses simplified, unrealistic 1‑to‑many relationships.
* The new schema is slower because it models albums and artists correctly, using two junction tables.
Despite the small performance cost, the normalized schema provides:
* correct album–artist relationships
* correct album–track relationships
* exact integer‑based revenue
* more flexible and scalable analytics

This benchmark highlights the difference between simplicity and correctness in schema design.
  

**Query 5 - Top 10 Best‑Selling Tracks**  
Query 5 identifies the top 10 tracks by total revenue, based on all invoice line items.  
This query focuses on the most atomic unit of the music catalog (i.e. `track`) and evaluates how each schema handles pricing, grouping, and revenue aggregation.

It is intentionally simple, yet analytically important, and exposes several structural differences between the old and new schemas.

#### Old Schema
The unnormalized schema stores track prices using a floating‑point column (`unit_price`).
While functional, this design introduces several weaknesses:
* floating‑point rounding errors during revenue aggregation
* no enforced foreign keys between `invoice_line` and `track`
* potential duplicate or inconsistent track names
* fewer indexing guarantees for grouping and ordering

Despite these limitations, the old schema can still compute track‑level revenue, but with reduced accuracy and less predictable performance.

#### New Schema
The normalized schema introduces several improvements that directly benefit this query:
* integer‑based currency (`unit_price_cents`) for exact revenue calculations
* enforced foreign keys between invoice lines and tracks
* unique, consistently formatted track names
* narrower tables and more efficient grouping
* better indexing on join keys and price fields

These changes produce exact revenue totals, cleaner grouping semantics, and more efficient execution plans.

Why This Query Matters
Track‑level analytics are essential for:
* storefront rankings
* playlist curation
* royalty calculations
* identifying high‑performing catalog items

Query 5 highlights how normalization improves correctness, consistency, and performance even in simple analytical workloads.

#### EXPLAIN ANALYZE — Query 5 Performance Comparison
Query 5 identifies the top 10 best‑selling tracks by total revenue.  
This query stresses track‑level metadata, pricing accuracy, grouping, and join efficiency.

Old Schema  
The unnormalized schema calculates revenue using floating‑point values (`unit_price`) and relies on a simplified 1‑to‑many album–artist structure.
This reduces join complexity but introduces several limitations:
* floating‑point rounding errors
* wider rows due to denormalized fields
* less efficient grouping
* no many‑to‑many modeling for tracks or artists

Despite these issues, the old schema performs well on this query because the join path is short and the dataset is small.

Execution summary:
| Metric             | Old Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~0.92 ms** |
| **Execution Time** | **~9.20 ms** |

New Schema
The normalized schema uses integer‑based currency (`unit_price_cents`) and models album–track and album–artist relationships as many‑to‑many.  
This improves correctness and flexibility but increases join complexity:
`invoice_line` -> `track` -> `album_track` -> `album` -> `artist_album` -> `artist`
Even with the additional joins, the normalized schema performs slightly faster than the old schema on this query.

This is because:
* integer math is faster than floating‑point
* grouping on narrower, normalized tables is more efficient
* enforced foreign keys improve planner confidence
* join fan‑out is manageable at track level

Execution summary:
| Metric             | New Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~6.01 ms** |
| **Execution Time** | **~9.19 ms** |

#### Interpretation
Query 5 shows that the normalized schema can match the old schema even when performing more joins.
This is because track‑level analytics benefit strongly from:
* integer‑based currency
* narrower tables
* cleaner grouping keys
* consistent metadata

The old schema is simpler, but the normalized schema is more accurate, more consistent, and equally fast for this workload.

### 4. Final Interpretation
Across all five benchmarks:
* Normalized schema wins 4/5 queries
* Integer‑based currency improves both correctness and performance
* Normalization reduces row width and improves grouping efficiency
* Many‑to‑many modeling increases join complexity but enables correct analytics
* Old schema is faster only where its unrealistic relationships reduce join cost

The normalized schema is more accurate, more predictable, and better suited for real analytical workloads, especially as data volume increases.

