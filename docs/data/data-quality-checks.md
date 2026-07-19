# Data Quality Checks — Overview Notes

## Summary
This document provides a technical breakdown of the data‑quality checks performed on the legacy schema.  
Each check includes methodology, findings, and BI implications.

#### 1. Null Value Checks
Objective: Identify missing values in key fields that could compromise referential integrity or analytical completeness.
* Methodology:
    - Scanned all primary keys and foreign keys for nulls.
    - Profiled descriptive fields.
* Findings:
    - No nulls in primary keys.
    - Several optional descriptive fields (e.g., phone numbers, addresses) showed inconsistencies.
* BI Impact:
    - Sparse attributes reduce segmentation accuracy.
    - Optional fields create unpredictable slicer behavior in Power BI.
    - Missing contact/location data weakens customer analytics.
    
#### 2. Duplicate Detection
Objective: Identify duplicate records that distort counts, KPIs, and catalog analytics.

* Methodology:
    - Checked uniqueness constraints across key entities.
    - Performed deduplication analysis on track, album, and artist.
* Findings:
    - Duplicate track records confirmed.
    - No enforced uniqueness constraints in the legacy schema.
* BI Impact:
    - Inflated track counts.
    - Misleading catalog KPIs.
    - Incorrect trend analysis when duplicates appear across time.
    
#### 3. Referential Integrity Validation
Objective: Ensure relationships between entities are complete, consistent, and enforceable.

* Methodology:
    - Validated foreign keys across all relationship pairs.
    - Checked for orphaned records and mismatched IDs.
* Findings:
    - No orphaned relationships detected.
    - Several relationships rely on implicit assumptions rather than explicit constraints.
* BI Impact:
    - Weak constraints increase risk of subtle errors.
    - Power BI may infer incorrect relationships or create ambiguous joins.
    - Analysts are forced to rely on assumptions instead of guaranteed structure.

#### 4. Formatting & Standardization Checks
Objective: Identify inconsistent formatting that affects joins, grouping, and geographic/financial analysis.

* Methodology:
    - Profiled address fields, phone numbers, and monetary values.
    - Checked for mixed formats, inconsistent casing, and floating‑point precision issues.
* Findings:
    - Addresses and phone numbers lacked validation rules.
    - Monetary values stored as floating‑point types.
    - No normalization or standardization applied.
* BI Impact:
    - Geographic analysis becomes unreliable.
    - Floating‑point values introduce rounding errors in revenue reporting.
    - Inconsistent formatting complicates ETL and increases risk of mismatched joins.
