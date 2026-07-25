# Genre Normalization Issues & Resolution Strategy - Technical Analysis

## Summary
This document provides a technical breakdown of the structural and semantic issues identified in the  
legacy `genre` table and outlines the strategy used to normalize genre data into a reliable many‑to‑many model.

#### 1. Non‑Atomic Genre Values
Objective: Identify genre labels that violate 1NF and cannot be represented cleanly in a normalized schema.
* Methodology:
    - Profiled all genre names for delimiters ("&", "/", "|", "and" etc).
    - Checked for multi‑genre combinations.
    - Assessed feasibility of splitting values into atomic components.
* Findings:  
Several genre names contained multiple genres combined into a single string.  
Since the following values violate 1NF, they cannot be represented cleanly in a normalized schema:
    - "Alternative & Punk"
    - "Hip Hop/Rap"
    - "Electronica/Dance"
    - "R&B/Soul"
    - "Sci Fi & Fantasy"  
* BI Impact:
    - Multi‑genre tracks were assigned single labels.
    - KPIs based on genres underrepresented tracks belonging into multiple genres.
    - Trend analysis was skewed because compound genres were treated as single categories.

**Resolution:**  
Compound genre names are split into atomic components.

#### 2. Compound Genre Normalization
Objective: Ensure a normalized schema by splitting compound labels into atomic genres.
* Methodology:
    - Identified overlaps (e.g. "Alternative" vs. "Alternative & Punk").
    - Merged groups before splitting compound labels.
* Findings:
    - Because the legacy schema allowed only one genre per track, tracks labeled with simpler genres were under‑classified.
    - Performing grouping before splitting avoids misclassification of split tokens.  
    For example:  
        * Tracks labeled "Alternative" are mapped to the same group as "Alternative & Punk", inheriting both "Alternative" and "Punk".  
        * Tracks labeled "Science Fiction" inherit "Sci Fi" and "Fantasy" from "Sci Fi & Fantasy".
* BI Impact:
    - Ensures consistent atomic representation, structural correctness and consistent many‑to‑many genre relationships.
    - Prevents misclassification caused by premature splitting.
 
**Resolution:**  
Genre merging is performed before splitting compound names, so that atomic genres inherit the full set of atomic genres implied by their compound counterparts.

#### 3. Transitional Mapping Tables
Objective: Provide a predetermined, auditable path from legacy genres to normalized atomic genres.
* Methodology:
    - Created mapping tables linking legacy genre IDs to canonical atomic genres.
    - Ensured all original track–genre relationships were preserved.
    - Validated mapping consistency across all entities.
* Findings:  
    - Transitional mapping tables were required to manage the transformation cleanly.  
    Supporting DataFrames:  
    `df_original_db_genre_table`  
    `df_original_db_track_table`  
    `df_map_genre_track_relationship`  
    `df_normalized_db_genre_table`  
    `df_normalized_db_genre_track_table`  
    `df_normalized_db_track_table`  
* BI Impact:
    - Guarantees auditability of genre transformations.
    - Stabilizes genre‑level KPIs and trend analysis.
    - Ensures consistent, atomic genre representation across the entire catalog.

**Resolution:**  
Mapping tables provide a deterministic, reversible pipeline from legacy genres to normalized atomic genres.

### Note on semantic accuracy:  
Some compound labels in the source dataset may have functioned as category headers rather than true hybrid genres.  
Splitting them may introduce minor semantic noise (e.g. tracks that received both "Sci‑Fi" and "Fantasy" genre IDs even if the original label was a broad shelving category).

This trade‑off is intentional and documented:
* Normalization and consistency are prioritized over perfect genre purity.  
* Future refinements may include manual review or external metadata to improve atomic genre assignments.
