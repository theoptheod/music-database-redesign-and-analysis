# Deletion Policy — Design Notes

## Summary
This document explains the global deletion rules that govern the entire database schema.  
It outlines how RESTRICT‑based foreign keys prevent accidental removal of catalog, geographic, employee, and financial entities.  
It clarifies why no cascading deletes exist and how manual relationship removal ensures safe, predictable operations.  
It highlights the entities protected by deletion constraints and the rationale behind this design.  
Together, these rules create a stable, audit‑safe, and integrity‑preserving data environment.

## Core Rules
* No entity is ever deleted automatically.
* No cascading deletes exist anywhere in the schema.
* Every foreign key uses `ondelete="RESTRICT"`, meaning: A parent cannot be deleted while any child references it.
* Relationships must be removed manually before deletion.
* Historical and catalog data remain intact.

## Protected Entities
* Tracks: Cannot be deleted if referenced by invoice lines, albums, genres, composers, playlists.
* Albums & Artists: Cannot be deleted if tracks or album relationships exist.
* Customers: Cannot be deleted if invoices exist.
* Employees: Cannot be deleted if they manage subordinates or represent customers.
* Geographic entities cannot be deleted while referenced by related entities.
* Lookup tables (`employee_level`, `employee_title`, cannot be deleted while employees reference them.

## Why RESTRICT Is Used
* Prevents accidental loss of catalog or financial history.
* Ensures referential integrity across all domains.
* Supports auditability and compliance.
* Guarantees stable relationships for analytics and reporting.