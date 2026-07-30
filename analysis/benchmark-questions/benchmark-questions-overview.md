## Benchmark Questions Overview

This project evaluates how the old (unnormalized) database and the new (normalized) schema perform when answering real  
analytical questions. Each benchmark query represents a common business scenario used in music analytics, digital storefronts, and reporting systems.

The five benchmark questions are:
1. Top‑Grossing Artists: “Which artists generated the most revenue?”
2. Most Popular Genre per Country: “What is the most popular music genre in each country?”
3. Top‑Spending Customer per Country: “Who is the highest‑spending customer in each country?”
4. Top‑Selling Albums: “Which albums generated the most revenue?”
5. Top 10 Best‑Selling Tracks: “What are the top 10 tracks by total revenue?”

Together, these questions form a complete analytical benchmark suite, covering:
* revenue aggregation
* customer analytics
* genre and album metadata
* many‑to‑many relationships
* integer vs floating‑point currency
* join complexity and scalability

Each query is implemented for both schemas, analyzed with EXPLAIN ANALYZE, and compared in terms of correctness, performance, and scalability.
