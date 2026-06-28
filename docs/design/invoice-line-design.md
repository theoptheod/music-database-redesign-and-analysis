# Invoice Line Design — Design Notes

## Overview
The original database records each purchased track as its own row in the `invoice_line table`.  
When a customer buys the same track multiple times within a single invoice, the system creates  multiple rows, each one representing a separate purchase event with a quantity of 1.  
This reflects an event‑based model rather than an aggregated one.

The redesigned schema preserves this behavior to maintain the original meaning of the data and avoid introducing assumptions about how purchases should be grouped or summarized.

## Legacy Model Behavior
In the original schema:
* Each row in `invoice_line` represents one purchase of one track
* `quantity` is always 1
* Buying the same track twice results in two rows, not one row with `quantity` 2
* Duplicate (`invoice_id`, `track_id`) pairs are therefore expected and valid

This design matches systems that record each purchase as its own event, rather than combining repeated purchases into a single summarized entry.

## Normalized Schema Design
The redesigned schema keeps the same event‑based structure:
* Duplicate (`invoice_id`, `track_id`) combinations are allowed
* Each row continues to represent a single purchase event
* No aggregation or consolidation is performed during migration
* `quantity` remains fixed at 1 for all rows
* Unit prices are stored as integer cents rather than floating‑point values

This ensures that analytical queries behave consistently across both schemas while improving financial accuracy.

## Why This Behavior Is Preserved
Several considerations support keeping the event‑based model:

**1. Data Fidelity**  
Aggregating purchases (e.g. combining duplicates into a single row with a higher quantity) would change the meaning of the data and break compatibility with the original system.

**2. Analytical Clarity**  
Event‑based purchase logs make it easier to analyze customer behavior patterns, demand per music track and purchase frequency. 
These insights can be lost or distorted when data is aggregated prematurely.

**3. Minimal Assumptions**
The legacy system does not indicate whether multiple purchases were intentional, accidental, or part of a bundle. Preserving the original structure avoids making assumptions that the data cannot support.

## Migration Notes
The migration process preserves the structure and meaning of each `invoice_line` record, but applies two important improvements:
* Unit prices are converted from floating‑point (`DOUBLE PRECISION`) values into integer cents to ensure financial accuracy.
* Quantities are converted from floating‑point to integer values, matching the event‑based purchase model where each row represents a single purchase.

No deduplication or consolidation is performed.  
Each row continues to represent a distinct purchase event exactly as in the original system.  
The only changes are the conversions needed to make the data accurate and consistent.

## Summary
The invoice‑line design maintains the original event‑based purchase model:
* Each row equates to one purchase
* Duplicate track purchases remain separate
* Quantity is stored as an integer
* Prices are stored as integer cents
* No aggregation or reinterpretation of purchase events

This approach protects the integrity of the data and ensures consistent analytical results across both schemas.