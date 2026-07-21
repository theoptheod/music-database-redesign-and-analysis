# Invoice Line Design - Design Notes

## Summary
The legacy system records each purchased track as a separate event, even when the same track is bought multiple times within a single invoice.
This event‑based structure provides a detailed view of customer behavior and purchase frequency, but it also means that duplicate (`invoice_id`, `track_id`) pairs are expected and meaningful.

The redesigned schema maintains this behavior to ensure consistent timestamp handling.  
Aggregating purchases into a single row (e.g. using `quantity` = 2) would introduce assumptions the dataset cannot support and would distort behavioral analytics.
By keeping the event‑based model intact the schema remains faithful to the original system and analytically reliable.

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
The legacy system does not indicate whether multiple purchases were intentional, accidental, or part of a bundle.  
Preserving the original structure avoids making assumptions that the data cannot support.

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
