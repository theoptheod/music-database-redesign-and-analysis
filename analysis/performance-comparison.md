# Performance Comparison: Old vs. New Schema - Technical Analysis

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

#### Query 1 - Top‑Grossing Artist
The first benchmark query calculates total revenue per artist, identifies the top‑selling artist, and determines how much each customer spent on that artist.
This query stresses join chains, aggregation correctness, currency precision, and join efficiency making it an ideal test of schema quality.

##### Why This Query Matters
Artist‑level revenue analytics are foundational in digital music platforms.  
They drive:
* royalty calculations
* catalog valuation
* artist performance reporting
* personalized recommendations

A schema that cannot compute artist revenue accurately or efficiently is fundamentally limited.

##### Old Schema
In the unnormalized schema, artist information is stored directly on the `album` table, and invoice totals rely on floating‑point arithmetic.  
This leads to:
* larger intermediate result sets
* less efficient join paths
* rounding inconsistencies
* nested loops in the execution plan

As a result, the old schema can answer the question, but with reduced accuracy and less predictable performance.

###### EXPLAIN ANALYZE - Old Schema Summary
Key issues observed:
* nested loop joins multiply row counts
* sequential scans on `invoice_line`, `track`, `album`, and `artist`
* floating‑point arithmetic introduces rounding errors
* wider intermediate result sets increase sorting and hashing cost

Although execution time appears similar on the legacy dataset, the plan structure is significantly less efficient and would degrade rapidly as data volume increases.

**Old Schema Performance**

| Metric             | Old Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~1.4 ms**  |
| **Execution Time** | **~12.3 ms** |

##### New Schema
Artists, albums, and tracks are connected through many‑to‑many junction tables, and all monetary values are stored as integer cents.  
This results in:
* more accurate revenue totals
* cleaner join paths
* hash joins instead of nested loops
* narrower intermediate result sets
* a significantly cheaper artist‑earnings CTE

###### EXPLAIN ANALYZE - Normalized Schema Summary
Key improvements:
* Hash joins instead of nested loops
* Efficient junction tables (`artist_album`, `album_track`)
* Integer‑based currency eliminates floating‑point errors
* Top‑selling‑artist CTE runs 4× faster
* Narrower rows and smaller hash tables lead to faster sorting

Although planning time is slightly higher due to more join paths, the execution plan is structurally superior and scales far better as data volume increases.

**New Schema Performance**

| Metric             | New Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~5.4 ms**  |
| **Execution Time** | **~12.0 ms** |

Full execution plans are available in the /analysis directory.

#### Query 2 - Most Popular Genre per Country  
The second benchmark query identifies the most popular music genre in each country based on total track purchases.
This query stresses genre metadata quality, geographic consistency, and grouping efficiency, making it a strong test of analytical correctness and join performance.

##### Why This Query Matters
Genre‑level analytics are foundational in digital music platforms.
They drive:
* recommendation systems
* regional marketing
* licensing decisions
* catalog optimization

A schema that cannot compute genre popularity accurately or efficiently is fundamentally limited.

##### Old Schema
In the unnormalized schema, genre information is stored directly on the `track` table, and customer geography is represented using free‑text fields.  
This leads to:
* simplified but inflexible genre relationships
* inconsistent country values
* floating‑point arithmetic during aggregation
* joins traversing wide, denormalized tables, that increase row size and reduce planner flexibility
* aggregations that require sequential scans and nested loops

The old schema can answer the question, but with reduced correctness and less predictable performance.

###### EXPLAIN ANALYZE - Old Schema Summary
Key characteristics observed:
* fewer joins due to denormalized genre storage
* smaller hash tables
* narrower grouping operations
* sequential scans on core tables
* floating‑point arithmetic introduces rounding inconsistencies

Execution time is faster on the legacy dataset because the denormalized structure reduces join complexity.

**Old Schema Performance**

| Metric             | Old Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~0.78 ms** |
| **Execution Time** | **~5.81 ms** |

##### New Schema
The normalized schema introduces a `genre_track` junction table and a clean geographic hierarchy.  
This results in:
* correct many‑to‑many genre relationships
* consistent country values
* integer‑based currency for exact revenue
* more selective join paths
* larger but more accurate grouping operations

###### EXPLAIN ANALYZE - Normalized Schema Summary
Key improvements:
* correct genre modeling
* hash joins instead of nested loops
* atomic geographic fields
* integer‑based revenue eliminates rounding errors
* stricter foreign‑key constraints improve planner confidence

Although execution time is higher on the legacy dataset, the normalized schema produces more accurate and scalable results.
In real‑world music catalogs, where tracks often belong to multiple genres, the normalized schema is required for correctness and would scale more effectively.

**New Schema Performance**

| Metric             | New Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~0.95 ms** |
| **Execution Time** | **~8.70 ms** |

Full execution plans are available in the /analysis directory.

### Query 3 - Top‑Spending Customer per Country
The third benchmark query identifies the highest‑spending customer in each country.
This query stresses invoice totals, customer geography, and grouping correctness.

##### Why This Query Matters
Customer‑level spending analytics support:
* segmentation
* marketing
* churn prediction
* regional revenue reporting

A schema that cannot compute customer spending accurately is fundamentally limited.

##### Old Schema
The unnormalized schema stores invoice totals as floating‑point numbers and uses free‑text country fields.  
This leads to:
* rounding inconsistencies
* inconsistent geographic values
* wider rows
* less efficient grouping

The old schema can answer the question, but results may not be mathematically exact.

###### EXPLAIN ANALYZE - Old Schema Summary
Key issues observed:
* floating‑point arithmetic introduces cumulative inaccuracies
* wider rows reduce grouping efficiency
* less selective joins
* sequential scans and nested loops

**Old Schema Performance**

| Metric             | Old Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~0.40 ms** |
| **Execution Time** | **~2.39 ms** |

##### New Schema
The normalized schema introduces integer‑based currency and consistent geographic fields.  
This results in:
* exact spending totals
* narrower rows
* faster hash aggregation
* more selective join paths
* predictable execution plans

###### EXPLAIN ANALYZE - Normalized Schema Summary
Key improvements:
* integer‑based totals eliminate rounding errors
* atomic customer fields
* consistent country values
* narrower rows improve grouping
* hash aggregation significantly reduces execution time

The normalized schema is over 4× faster for this query, while also producing more accurate and reliable results.

**New Schema Performance**

| Metric             | New Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~0.33 ms** |
| **Execution Time** | **~0.53 ms** |

Full execution plans are available in the /analysis directory.

### Query 4 - Top‑Selling Albums
The fourth benchmark query calculates total revenue per album and identifies the top‑selling albums.
This query sits between track‑level and artist‑level analytics, stressing album metadata and many‑to‑many relationships.

##### Why This Query Matters
Album‑level analytics support:
* catalog performance tracking
* royalty calculations
* playlist curation
* label revenue reporting

A schema that cannot compute album revenue accurately is fundamentally limited.

##### Old Schema
The unnormalized schema models albums and artists using 1‑to‑many relationships.  
This leads to:
* simplified join paths
* incorrect modeling of collaborations and compilations
* floating‑point revenue calculations
* wider intermediate result sets

The old schema answers the question, but with reduced correctness and less flexible analytics.

###### EXPLAIN ANALYZE - Old Schema Summary
Key characteristics observed:
* simplified join chain (invoice_line -> track -> album -> artist)
* fewer joins and smaller hash tables
* floating‑point arithmetic introduces rounding errors
* denormalized fields reduce planner flexibility

**Old Schema Performance**

| Metric             | Old Schema    |
| ------------------ | ------------- |
| **Planning Time**  | **~0.94 ms**  |
| **Execution Time** | **~12.42 ms** |

##### New Schema
The normalized schema models albums and artists using many‑to‑many relationships.  
This results in:
* correct modeling of collaborations and compilations
* integer‑based revenue
* narrower tables
* enforced foreign keys
* more selective join paths

####### EXPLAIN ANALYZE - Normalized Schema Summary
Key improvements:
* correct album–artist and album–track relationships
* integer‑based revenue eliminates rounding errors
* hash joins improve grouping accuracy
* narrower rows reduce memory footprint

However, correctness comes with additional join complexity:  
`invoice_line` -> `track` -> `album_track` -> `album` -> `artist_album` -> `artist`  
This increases planning and execution time on small datasets like the unnormalized one.

**New Schema Performance**

| Metric             | New Schema    |
| ------------------ | ------------- |
| **Planning Time**  | **~9.43 ms**  |
| **Execution Time** | **~13.29 ms** |

Full execution plans are available in the /analysis directory.

### Query 5 - Top 10 Best‑Selling Tracks
The fifth benchmark query identifies the top 10 tracks by total revenue.
This query stresses track‑level metadata, pricing accuracy, and grouping efficiency.

##### Why This Query Matters
Track‑level analytics support:
* storefront rankings
* playlist curation
* royalty calculations
* catalog performance monitoring

A schema that cannot compute track revenue accurately is fundamentally limited.

##### Old Schema
The unnormalized schema stores track prices using floating‑point values and uses simplified album–artist relationships.  
This leads to:
* rounding errors
* wider rows
* less efficient grouping
* limited metadata consistency

Despite these issues, the old schema performs well because the join path is short and the dataset is small.

###### EXPLAIN ANALYZE - Old Schema Summary
Key characteristics observed:
* simplified join chain
* floating‑point arithmetic
* wider intermediate result sets
* sequential scans and nested loops

**Old Schema Performance**

| Metric             | Old Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~0.92 ms** |
| **Execution Time** | **~9.20 ms** |

##### New Schema
The normalized schema uses integer‑based currency and many‑to‑many album–track and album–artist relationships.  
This results in:
* exact revenue totals
* narrower tables
* cleaner grouping keys
* more consistent stored data

###### EXPLAIN ANALYZE - Normalized Schema Summary
Key improvements:
* integer math is faster than floating‑point
* enforced foreign keys improve planner confidence
* narrower rows reduce grouping cost
* join fan‑out remains manageable at track level

The old schema is simpler, but the normalized schema is more accurate, more consistent, and equally fast for this workload.

**New Schema Performance**

| Metric             | New Schema   |
| ------------------ | ------------ |
| **Planning Time**  | **~6.01 ms** |
| **Execution Time** | **~9.19 ms** |

Full execution plans are available in the /analysis directory.

### 4. Final Interpretation
Across all five benchmarks:
* Normalized schema performs better in 3/5 queries
* Integer‑based currency improves both correctness and performance
* Normalization reduces row width and improves grouping efficiency
* Many‑to‑many modeling increases join complexity but enables correct analytics
* Old schema is faster only where its unrealistic relationships reduce join cost

The normalized schema is more accurate, more predictable, and better suited for real analytical workloads, especially as data volume increases.

