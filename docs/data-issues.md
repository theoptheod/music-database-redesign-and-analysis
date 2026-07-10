# Data Issues — Design Notes

## Summary
This document provides a technical breakdown of structural issues identified in the legacy dataset.  
Each issue includes methodology, findings, and BI implications.

#### 1. Duplicate Records
Objective: Identify duplicate entities and assess whether safe deduplication is possible.
* Methodology:
    - Investigated uniqueness across `track`, `album`, and `artist`.
    - Checked invoice references to determine whether duplicates were used in transactions.
    - Compared metadata (duration, bytesize) across duplicate entries.
* Findings:
    - Duplicate tracks existed across multiple albums.
    - Most duplicates had no invoice references and appear to be dataset artifacts.
    - Two duplicate tracks ("Imagine" and "Gimme Some Truth" from the "Instant Karma: The Amnesty International Campaign to Save Darfur" album), were referenced in `invoice_line`.
    - Metadata differences (duration, bytesize) could not be validated without source media.
* BI Impact:
    - Deduplication risks corrupting invoice history.
    - Catalog KPIs may count tracks multiple times.
    - Trend analysis becomes ambiguous when duplicates appear across time.
    - Duration‑based metrics (e.g. total listening time) may be inaccurate.

**Resolution:**  
All duplicates were retained to preserve invoice integrity.

#### 2. Incomplete or Non‑Applicable Address Data
Objective: Assess reliability of geographic fields and identify structural limitations.
* Methodology:
    - Profiled customer and invoice address fields.
    - Identified placeholder values (e.g. "None") and inconsistent NULL usage.
    - Evaluated the validity of country‑specific fields (e.g. state, postal code).
* Findings:
    - Address fields mixed NULLs, placeholders, and inconsistent casing.
    - Schema assumed US‑style address structures, which do not apply globally.
    - Several countries lack states or postal codes.
* BI Impact:
    - Geographic segmentation was unreliable or impossible.
    - Power BI slicers behaved inconsistently due to mixed usage of NULL/placeholders.
    - Regional KPIs (e.g. revenue by state) were structurally invalid for many customers.

**Resolution:**  
Placeholder values converted to SQL NULLs.  
Optional Postal/ZIP codes, since they are not always applicable.  
Administrative divisions modeled per country.

#### 3. Inconsistent Composer Information
Objective: Evaluate reliability of composer metadata and enforce atomic modeling.
* Methodology:
    - Profiled the composer field for NULLs, placeholders, and inconsistent formatting.
    - Checked for multi‑composer tracks.
    - Assessed feasibility of modeling composers as a normalized entity.
* Findings:
    - Composer values ranged from valid names to "anonymous", NULLs, and whitespace.
    - Multi‑composer tracks could not be represented.
    - Composer information violated atomicity and could not support contributor analytics.
* BI Impact:
    - KPIs relating to composers were unreliable.
    - Catalog analytics lacked contributor attribution.
    - Multi‑composer relationships could not be modeled or analyzed.

**Resolution:**  
Introduced `composer` entity and `composer_track` junction table.  
Allowed NULL for unknown composers but prohibited empty/whitespace values.

#### 4. Limitations Due to Missing Source Media
Objective: Determine whether metadata inconsistencies can be resolved without original audio files.
* Methodology:
    - Compared duration and bytesize across duplicate tracks.
    - Attempted to infer correctness based on invoice references.
    - Evaluated if the metadata differences were fixable without the original audio files.
* Findings:
    - Duplicate tracks differed in duration and bytesize.
    - No dependable source existed to determine correctness.
    - Metadata inconsistencies could not be resolved.
* BI Impact:
    - Duration‑based KPIs may be inaccurate.
    - Quality metrics based on file size cannot be trusted.

**Resolution:**  
No deduplication or merging performed.

#### 5. Preventing Future Issues
Objective: Ensure redesigned schema prevents re‑introduction of legacy issues.
* Methodology:
    - Reviewed normalization requirements (2NF/3NF).
    - Added constraints to enforce uniqueness and referential integrity.
    - Introduced atomic modeling for contributors and addresses.
* Findings:
    - Legacy schema lacked constraints and normalization.
    - Several issues stemmed from structural gaps rather than data errors.
* BI Impact:
    - Future data will be structurally consistent.
    - BI reports will rely on guaranteed relationships rather than assumptions.
    - Segmentation, catalog analytics, and financial reporting become more reliable.

**Resolution:**  
Enforced uniqueness constraints.  
Added foreign keys and relationship rules.  
Normalized address and composer structures.
