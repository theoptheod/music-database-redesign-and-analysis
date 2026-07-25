# ETL Pipeline - Technical Analysis

## Summary
This document describes the complete ETL workflow used to migrate the old dataset into a fully normalized PostgreSQL schema.   
It uses Pandas DataFrames for staging, SQLAlchemy ORM models for structure, and a strict approach to referential integrity.  
The goal of the pipeline is to load the data, clean it, validate relationships and finally ensure that everything fits the rules, before it’s written into the final schema.  
This keeps the database consistent and prevents issues that could affect BI analysis later on.

#### 1. Staging Layer: Pandas DataFrames
The staging layer pulls data directly from the original database using SQLAlchemy and loads each table into a Pandas DataFrame.  
Each one of the created DataFrames, acts as the controlled environment where cleaning and validation happen before anything reaches the new database.

Responsibilities of the staging layer:
* Standardize column names and types across all tables.
* Normalize missing values by converting PostgreSQL NULLs and Pandas NA types into a unified representation ("None"), so the ETL process behaves consistently.
* Deduplicate catalog entities with the removal of repeated artists, albums, genres, and composers before they enter the normalized schema.
* Validate foreign‑key relationships in order to prevent broken relationships later in the pipeline.
* Prepare surrogate keys and junction‑table mappings to ensure that relationships are clean and explicit.

The staging layer catches inconsistencies early so they never reach the final database.

#### 2. Universal NA Cleaning Function
When data is pulled from the original PostgreSQL database into Pandas, missing values can appear in several different forms (NaN, NaT, pd.NA).  
These behave differently inside Pandas and can cause type issues, when inserting into the new normalized schema.  
To avoid this, the pipeline applies a universal cleaning step that converts all representation of missing values into a single, consistent Python "None".  

This ensures:
* Consistent null handling across the entire ETL process
* Safe insertion into PostgreSQL without NA‑related type errors
* Predictable behavior during validation, especially when checking foreign keys
* Cleaner downstream transformations in the normalized schema

This step keeps the pipeline stable and prevents subtle issues that could affect BI models later.

#### 3. ORM Schema Definition (SQLAlchemy Declarative Base)
The normalized schema is defined using SQLAlchemy ORM models.  
Each model represents a table and includes its columns, constraints, and relationships.  
This gives the ETL pipeline a strict structure to load into.

The ORM layer ensures:
* Accurate table definitions
* Clear foreign‑key relationships
* Enforced domain rules such as NOT NULL and CHECK constraints
* Consistent mapping between DataFrames and tables

By relying on ORM models, the pipeline guarantees that every inserted row follows the rules of the normalized schema.

#### 4. Converting DataFrames to Row Dictionaries
SQLAlchemy’s bulk insert mechanism expects data in a row‑oriented dictionary format.  
After cleaning, each DataFrame is converted using:  
```
df.to_dict(orient="records")
```  
This produces a list of dictionaries, where each dictionary represents one row.

This allows:
* Fast bulk inserts
* Lower overhead than ORM object creation
* Consistent mapping to SQLAlchemy models

This step keeps the pipeline efficient while still respecting constraints.

#### 5. Model Mapping: DataFrame to ORM Class
The pipeline uses a mapping dictionary that connects each DataFrame name to its corresponding ORM model.  
This avoids hard‑coding and makes the ETL loop flexible.

Benefits:
* Dynamic table selection
* Easy extension for new tables
* Cleaner and more maintainable ETL code

This mapping is the backbone of the automated loading process.

#### 6. Bulk Insert Using SQLAlchemy Sessions
The pipeline uses SQLAlchemy’s bulk insert pattern to load large volumes of data efficiently while still respecting constraints.

Each insert:
* Runs inside a session
* Uses insert(model)
* Commits only when all rows pass validation
* Rolls back on any violation

This ensures safe, high‑volume loading without risking partial or corrupted inserts.

#### 7. Foreign‑Key Safe Insertion Order
Because the schema is normalized, tables must be inserted in an order that respects dependencies.  
So we insert parent tables first, followed by children and finally junction tables.

This prevents:
* Broken foreign keys
* Orphaned records
* Invalid many‑to‑many relationships

The insertion order is explicitly defined and followed by the ETL loop.

#### 8. Automated ETL Loop
The final loop ties everything together:
* Select DataFrame
* Clean missing values
* Convert to row dictionaries
* Select ORM model
* Bulk insert
* Commit

This creates a predictable, repeatable, and constraint‑driven loading process.
