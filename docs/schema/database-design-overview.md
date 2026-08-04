# New Database Overview - Design Notes

## Summary
This document provides a full architectural explanation of the redesigned PostgreSQL schema,  
outlining the three major domains: music catalog, geographic hierarchy, and customer/employee/invoice management.

It details the normalization strategy, the rationale behind atomic entities, the use of explicit many‑to‑many relationships  
and the relational design principles applied throughout the schema, including 3NF, check constraints, indexing, and naming conventions.

Finally, it highlights the analytical benefits of the redesign and how the new structure  
supports reliable contributor analytics, geographic segmentation, and customer/invoice reporting.

## Motivation for Redesign
The original schema contained multiple structural issues:
* non‑atomic contributor fields
* ambiguous many‑to‑many relationships stored as text
* inconsistent formatting
* weak normalization across geographic and customer domains

These problems required extensive preprocessing and made BI reporting fragile.  
The new PostgreSQL schema addresses these issues through a complete redesign rather than incremental fixes.

## Architectural Domains
The schema models three major domains:

**1. Music Catalog**  
Includes albums, artists, composers, genres, media types, playlists and tracks.  
Supports both one‑to‑many and many‑to‑many relationships through explicit junction tables  
(`artist_album`, `composer_track`, `genre_track`, `playlist_track`, `album_track`).  
Constraints and indexes ensure data consistency and efficient querying.

**2. Geographic Hierarchy**  
A fully normalized geographic model representing countries, administrative divisions, cities, postal/ZIP codes and addresses.  
Supports countries with or without postal codes, enforces uniqueness within geographic scopes, and ensures clean standardized text fields.

**3. Customer, Employee & Invoice Management**  
Models customer identity, employee hierarchy, job titles, seniority levels, and invoice documentation.  
Self‑referencing relationships support multi‑level organizational structures.  
Invoice data is denormalized intentionally to preserve historical accuracy.

## Design Principles
The schema follows strong relational design principles:
* Third Normal Form (3NF)
* Meaningful check constraints
* Consistent indexing strategy
* Clear naming conventions
* Robust many‑to‑many modeling
* Self‑referential hierarchy support

These principles ensure predictable joins, stable relationships, and reliable analytical behavior across all domains.

## Core Schema Components
#### Contributor Dimensions  
Atomic entities for artists, composers, and genres, each with surrogate keys and clean text constraints.  
Each dimension supports many‑to‑many relationships via junction tables.

#### Catalog Entities
Albums, tracks, media types and playlists are modeled with strict constraints, indexes and explicit associations.  
Tracks serve as a central node linking composers, genres, playlists, albums and invoice lines.

#### Geographic Entities
Countries -> Administrative Divisions -> Cities -> Addresses -> Customers/Employees  
Each level enforces uniqueness and clean text fields, ensuring reliable geographic segmentation.

#### Customer & Employee Entities
Employees have titles, levels, addresses, and hierarchical reporting structures.  
Customers link to addresses and representatives.  
Both enforce unique emails and clean text constraints.

#### Invoice & InvoiceLine
Invoices store denormalized billing information for historical accuracy.  
InvoiceLine links purchased tracks to invoices with quantity and pricing constraints.

## Analytical Implications
The redesigned schema provides:
* Reliable contributor analytics
* Clean geographic segmentation
* Stable joins for BI tools
* Accurate customer and employee reporting
* Clear separation of identity vs. relationship
* Reduced preprocessing overhead
* An easy to expand design when new data are added.
