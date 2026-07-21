# Timezone Normalization - Design Notes

## Summary
The original dataset stored timestamps without timezone information, making it impossible to determine whether events were recorded in server time, customer local time, or `UTC`.
This ambiguity does not affect day or week based analysis, but it makes hour‑level behavior and local time insights unreliable.

To ensure consistent interpretation across SQL, Python, and BI tools, all timestamps in the redesigned schema are stored as `UTC` using `TIMESTAMPTZ`.
The values are preserved exactly as they appeared in the source data, but the new type guarantees stable, predictable handling during analysis and avoids introducing assumptions the dataset cannot support.

## Why UTC Normalization Was Necessary

### Ambiguity in the Source Data
The presence of `billing_country` information does not resolve the timezone problem.

Since the original application did not record timezone offsets, we have no way to know whether:
* The timestamp reflects the customer’s local time
* The timestamp reflects the server’s timezone
* The timestamp was already normalized by the application
* The timestamp was stored in `UTC` originally

Any attempt to adjust timestamps using `billing_country` would introduce fabricated data and distort analytical results.

### Preserving Analytical Integrity
By treating all timestamps as `UTC`:
* The original chronological ordering is preserved
* No artificial timezone shifts are introduced
* Cohort and retention analysis remain accurate
* BI tools interpret timestamps consistently

This approach avoids making assumptions the dataset cannot support.

## Schema Implementation

### Column Types
All timestamp fields use:
```
TIMESTAMPTZ NOT NULL
```
This ensures:
* PostgreSQL stores all values in UTC internally
* Timezone information is preserved correctly
* Downstream tools receive unambiguous timestamps

## Migration Logic

### Source Data Handling
During migration, timestamps were treated as `UTC` and inserted directly into `TIMESTAMPTZ` columns without modification.
This decision reflects the absence of reliable timezone data in the source dataset.

This approach ensures:
* Predictable behavior
* No accidental timezone shifts
* Preservation of the original event sequence

### Why Billing Country Was Not Used
Although customer billing locations exist, they cannot be used to infer timezone data because:
* Billing country can differ from customer's timezone
* Customers may purchase while traveling
* The original application may have used server time

Attempting to adjust the timestamps would introduce inaccuracies rather than correct them.

## Analysis‑Time Considerations

### Cohort and Retention Analysis
Cohort analysis relies on relative time, such as:
* Days since first purchase
* Weeks since signup
* Month‑over‑month retention

These calculations are unaffected by timezone ambiguity, making `UTC` storage fully appropriate.

### What Analyses Are Possible
Because timestamps contain valid calendar dates, the following analyses remain fully reliable:
* day‑of‑week patterns
* month‑over‑month revenue trends
* cohort windows
* retention curves

### What Analyses Are Not Possible
The dataset does not support analyses that depend on the local time of day, such as:
* Hour‑of‑day behavior
* Local peak purchase times
* Regional seasonality tied to local hours
* Time‑of‑day churn indicators

These require original timezone offsets, which the dataset does not contain.

## Data Validation
During migration, the following checks were performed:
* All timestamps successfully cast to `TIMESTAMPTZ`
* No invalid or out-of-range dates existed
* Event ordering remained consistent
* No unintended timezone shifts occurred

These checks ensured that the normalized timestamps accurately reflect the original event sequence.

## Future Considerations
If future datasets include data like customer timezone preferences, server‑side offsets, application‑level timezone metadata or regional purchase logs the schema will properly handle timezone conversion and localization.

The current `UTC` design provides a stable foundation for both present and future analytical needs.
