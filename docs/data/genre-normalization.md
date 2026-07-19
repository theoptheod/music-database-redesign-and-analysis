# Genre Normalization Issues & Resolution Strategy — Overview Notes

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

#### 2. Semantically Overlapping Genres
Objective: Identify genre labels that represent the same conceptual category but were stored separately.
* Methodology:
    - Compared compound genres to simpler variants.
    - Identified conceptual overlaps (e.g. Alternative vs. Alternative & Punk).
    - Evaluated semantic meaning of each label.
* Findings:  
    - Pairs of genres represented the same conceptual space but were stored separately.
    - Because the legacy schema allowed only one genre per track, tracks labeled with simpler genres were under‑classified.
* BI Impact:
    - Genre trends were fragmented across multiple labels.
    - Tracks were missing relevant genre associations.
    - Cross‑genre analytics were incomplete or misleading.

**Resolution:**  
Simpler genres inherit the full set of atomic genres implied by their compound counterparts.

#### 3. Merge‑Before‑Split Strategy
Objective: Ensure semantic consistency before splitting compound genre labels.
* Methodology:
    - Grouped semantically related genres.
    - Merged conceptual groups before splitting compound labels.
    - Ensured that semantic meaning was preserved.
* Findings:  
    - Performing semantic grouping before splitting avoids misinterpretation of split tokens.  
    For example:  
    Tracks labeled "Alternative" are mapped to the same conceptual group as "Alternative & Punk", inheriting both "Alternative" and "Punk".  
    Tracks labeled "Science Fiction" inherit "Sci Fi" and "Fantasy" from "Sci Fi & Fantasy".  
* BI Impact:
    - Preserves original intent of genre assignments.
    - Ensures consistent atomic representation.
    - Prevents misclassification caused by premature splitting.

**Resolution:**  
Genre merging is performed before splitting compound names.

#### 4. Transitional Mapping Tables
Objective: Provide a deterministic, auditable path from legacy genres to normalized atomic genres.
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
