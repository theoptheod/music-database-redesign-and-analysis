# Address Normalization - Design Notes

## Summary
The legacy schema stored addresses as free‑form text across customers, employees, and invoices.  
This led to inconsistent spelling, duplicated locations, and unreliable geographic grouping that undermine revenue per region reporting, customer segmentation and Power BI mapping.

The redesigned schema introduces a normalized geographic hierarchy for customers and employees, while invoices retain embedded billing fields to preserve legal immutability.
This hybrid approach ensures clean, validated geographic data for analytics while maintaining historically accurate billing information for financial records.

## Legacy Schema Limitations
1. **Free‑form text fields**  
    The original schema stored address, city, state, country, postal_code as independent text fields.  

    This caused:
    * inconsistent spellings (“Montréal” vs “Montreal”)
    * inconsistent abbreviations (“QC” vs “Quebec”)
    * inconsistent postal code formats
    * no way to enforce valid country names
    * no ability to deduplicate addresses

2. **No geographic hierarchy**  
    Countries, states, cities, and postal codes were not modeled as entities.
   
    This prevented:
    * joining customers by region
    * aggregating revenue by country
    * validating postal codes
    * enforcing relationships between cities and states

4. **Invoice addresses were mutable**  
    In the legacy schema, invoice billing fields were tied to the customer’s current address.  
    If a customer moved, historical invoices would change, which is legally incorrect.
    
## Normalized Geographic Model
The redesigned schema introduces a fully normalized geographic hierarchy:
* Country
* Postal/Zip Code
* Administrative Division (state, province, region)
* City
* Address

This structure ensures consistent, validated, reusable geographic data.

## Schema Implementation

### Country
The `country` table stores canonical country names and ISO codes.

Key features:
* ISO code length enforced (2 or 3 characters)
* Uppercase ISO codes
* Unique ISO codes
* Non‑blank names
* Indexed for fast lookup

This provides a stable foundation for all geographic relationships.

### Postal/Zip Code
The `postal_zip_code` table stores postal or zip codes that relate to a country.

Key features:
* Unique per country
* Non‑blank codes
* Indexed for efficient filtering

This allows consistent postal code validation and reuse.

#### Handling Missing Postal Codes & Data Normalization Rules
The legacy database contains customers and invoices with missing postal codes.  
To maintain a clean and semantically correct geographic hierarchy, the redesigned schema enforces:
* `postal_zip_code`.`code` is NOT NULL
* `address`.`postal_zip_code_id` is NULLABLE
* Only real postal codes are inserted into `postal_zip_code`
* Missing postal codes do not generate placeholder rows

This ensures that the postal catalog contains only valid, reusable postal codes, while addresses with missing postal codes are represented by `postal_zip_code_id` = `NULL`.
Customers with incomplete address data are preserved without creating artificial postal‑code entries, and invoice billing fields remain immutable snapshots of the original transaction.

This design keeps the geographic hierarchy clean, prevents polluted foreign‑key relationships, and accurately reflects real‑world data where postal codes may be optional or unavailable.

### Administrative Division
The `administrative_division` table models states, provinces, or regions.

Key features:
* Relate to a specific country
* Unique per country
* Non‑blank names and types
* Indexed for efficient joins

This supports global address formats where administrative divisions vary widely.

### City
The `city` table stores city names scoped to an administrative division.

Key features:
* Unique per division
* Non‑blank names
* Indexed for fast lookup

This prevents ambiguous duplicates (for example multiple cities with the same name).

### Address
The `address` table represents a complete physical address.

Fields include:
* `address_line_1` (required)
* `address_line_2` (optional)
* `city_id`
* `postal_zip_code_id`

Key features:
* Clean constraints on street lines
* Foreign keys to city and postal code
* Shared by customers and employees

This provides a reusable, validated address entity.

## Customer and Employee Address Handling

### Customer
Customers through `address_id` reference a normalized address.

This replaces the legacy free‑form fields:
* `address`
* `city`
* `state`
* `country`
* `postal_code`

Benefits:
* consistent geographic data
* deduplication of addresses
* clean joins for analytics
* optional address support for customers without a known location

### Employee
Employees must have a normalized address (`address_id` is non‑nullable).

Benefits:
* consistent internal directory
* location‑based reporting
* future HR analytics

## Invoice Billing Addresses

### Handling Missing Billing Postal Codes and Administrative Divisions
The legacy invoice data contains missing billing postal codes and administrative divisions, represented by the string "None".  
Because invoice billing fields are preserved as immutable text snapshots, they are not normalized and do not reference the geographic hierarchy.

During ETL, all literal "None" strings are converted to actual NULL values to ensure semantic correctness and prevent polluted text fields.  
No placeholder postal codes or administrative divisions are created, and invoices with missing billing information remain valid financial records.

This approach maintains the legal immutability of invoice data while ensuring that missing values are represented consistently in the normalized database.

### Embedded Invoice Billing Fields
Invoices retain embedded billing fields:
* `billing_address`
* `billing_city`
* `billing_administrative_division`
* `billing_country`
* `billing_postal`

These fields are not normalized and do not reference the address table.

This design was selected since an invoice is a legal document.
* It must preserve the exact billing information used at the time of purchase
* It must not change if a customer updates their address
* It must match the printed invoice exactly
* It must remain immutable for auditing and compliance

This separation ensures both:
* normalized, reusable addresses for operational data
* immutable, embedded addresses for financial records

## Data Validation
During migration:

* All legacy address fields were trimmed and validated
* Postal codes were normalized into the `postal_zip_code` table
* Countries were mapped to ISO codes
* Cities and administrative divisions were deduplicated
* Customer and employee addresses were reconstructed into the normalized hierarchy
* Invoice billing fields were preserved

This ensured both data quality and legal correctness.

## Benefits of the Normalized Model
Consistency: All geographic entities are validated and deduplicated  
Referential integrity: Countries, states, cities, and postal codes are linked correctly  
Analytics: Revenue by country, customer distribution by region, employee location reporting  
Extensibility: Future geocoding, timezone mapping, or analytics based on geographical regions  
Legal correctness: Invoice addresses remain immutable snapshots

## Future Considerations
The normalized hierarchy supports future enhancements such as:
* geospatial coordinates
* region‑level rollups
* timezone mapping
* address validation APIs
* customer mobility analysis

The schema is designed to grow without requiring changes to invoice records.
