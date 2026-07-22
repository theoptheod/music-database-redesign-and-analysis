# Monetary Values - Design Notes

## Summary
Accurate financial reporting is a core requirement for any analytical system.   
The original dataset stored prices using `DOUBLE PRECISION`, a binary floating‑point type that introduces precision errors for values like 0.1 or 19.99.

This produces artifacts like:
```
19.99 -> 19.989999999999998
1.29  -> 1.2899999999999999
```
These errors accumulate during aggregations, exports, and transformations.  
These inconsistencies directly affect revenue reporting, customer lifetime value calculations, and any BI workflow that relies on precise monetary values.

To ensure consistent and accurate financial insights across SQL, Python, and Power BI, all monetary values in the redesigned schema are stored as integer cents.
This eliminates floating‑point ambiguity entirely and guarantees that financial metrics remain stable across tools and environments.

## Schema Implementation

### Column Types
All monetary fields use `INTEGER NOT NULL` with explicit non‑negative constraints:
```
unit_price_cents = Column(Integer, nullable=False)
CheckConstraint("unit_price_cents >= 0", name="ck_unit_price_cents_non_negative")
```
This guarantees that every monetary field contains an integer value of zero or greater.

This pattern is applied to:
* `track`.`unit_price_cents`
* `invoice`.`invoice_total_cents`
* `invoice_line`.`unit_price_cents`

### Naming Convention
All monetary columns end with `_cents` to make the unit explicit and avoid ambiguity in SQL queries or BI tools.

## Migration Logic

### Source Data Handling
The new schema expects integer cents, and the ETL pipeline inserted the values directly into the `_cents` columns without applying rounding or currency formatting.  

This approach ensures:
* No floating‑point operations during ETL
* No rounding or formatting applied prematurely
* A clean separation between storage, analysis, and presentation
* Consistent behavior across SQL, Python and BI tools

## Analysis‑Time Conversion
When answering analytical questions or benchmarking queries, monetary values were converted using a simple transformation:
```
SELECT
ROUND(SUM("invoice"."invoice_total_cents") / 100.0, 2)
FROM "invoice";
```
This ensures:
* Clear, intentional formatting
* No hidden rounding rules
* Consistent results across environments

## Data Validation
Several validation checks were performed to ensure data integrity:
* All `_cents` values were confirmed to be non‑negative
* No fractional cents existed in the source data
* Invoice totals matched the sum of their invoice lines
* No floating‑point artifacts were carried over from the legacy schema
