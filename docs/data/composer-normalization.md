# Composer Normalization & Composer-Track Mapping - Technical Analysis

## Summary
This document details the methodology used to normalize composer data and construct the Composer–Track relational model.  
It explains the motivation for normalization, the manual mapping for messy inputs, and the automated pipeline for cleaning and standardizing composer names.
Finally, it outlines key analytical implications, including improved contributor reporting, stable relationships, and handling of edge cases.

#### 1. Problem Context
The original `composer` column in the `track` table was structurally unreliable:
• Multiple separators used interchangeably (commas, slashes, semicolons, ampersands, “and”).
• Shorthand formats: “U2/ Edge, The”.
• Reversed name order: “Dolmayan, John.”
• Non‑ASCII hyphens and punctuation.
• Stage names and abbreviations: AC/DC, R.E.M., The Edge.  
These inconsistencies made automated parsing fragile.  
Regex produced unpredictable splits and wan't able to correctly identify composer entities.

#### 2. Manual Mapping Layer
A Python dictionary (`composer_manual_split_dict`) defines canonical splits for problematic raw strings.  
Any string present in this dictionary:
• Bypasses all automated normalization
• Returns a pre‑validated list of canonical composer names
• Ensures stability for known messy cases
This layer prevents regressions and keeps the pipeline predictable.

#### 3. Automated Normalization Pipeline
For all other strings, the pipeline applies deterministic transformations:   

**1. Separator Normalization**  
    Function: `normalize_separators()`  
    Purpose: Convert all separators (e.g. ",", "/", ";", "&", "and") into a single canonical delimiter ("||").  
    This guarantees that every composer field can be split reliably.  
    
**2. Splitting Into Composer Lists**  
    After normalization we move on to splitting.  
    For example:  
    ```
    "Adrian Smith||Bruce Dickinson||Steve Harris"
    ```  
    becomes  
    ```
   ["Adrian Smith", "Bruce Dickinson", "Steve Harris"]
    ```  
    This produces atomic raw names for further cleaning.  
    
**3. Atomic Name Normalization**  
    Function: `normalize_atomic_name()`  
    Responsibilities:  
        • Trim whitespace  
        • Normalize spacing around punctuation  
        • Standardize capitalization  
        • Apply exception rules (e.g. "ac/dc" becomes "AC/DC")  
    This step ensures each composer is represented consistently across the dataset.  
    
**4. Building the Unique Composer List**  
    All normalized names are collected into a Python set:  
        • Guarantees uniqueness  
        • Prevents duplicates caused by formatting differences  
    The set is then alphabetized to produce a stable canonical list.  
    
**5. Assigning Composer IDs**  
    Each unique composer receives a surrogate key (`composer_id`).  
    This ensures:  
        • Stable foreign‑key relationships  
        • Predictable joins  
        • BI‑friendly composer analytics   
        
**6. Building the `composer_track` Junction Table**  
    Tracks may have multiple composers, so a many‑to‑many structure is required.  
    For each track:  
       • Read `track_id`  
       • Iterate through its normalized composer list  
       • Look up each composer’s `composer_id`  
       • Append (`track_id`, `composer_id`) to the junction table  
       • Assign a surrogate `composer_track_id` for database consistency  
    This produces a clean relational model:  
        •  `composer`  
        • `composer_track`  
        • `track`  

#### 4. Analytical Implications
##### BI Reliability
The normalized model enables:
* Accurate composer reporting
* Clean joins between tracks and composers
* Stable aggregation of composer activity
* Reliable filtering and grouping (e.g. tracks composed by Brian May)

##### Data Quality Improvements
The pipeline resolves:
* Non‑atomic composer fields
* Formatting inconsistencies
* Ambiguous shorthand names
* Mixed separators
* Stage name capitalization issues

##### Future‑Proofing
The manual mapping layer allows:
* Controlled overrides for new messy cases
* Predictable behavior without rewriting regex logic
* Easy extension as new data sources are added

