# Phone Number Normalization - Design Notes

## Summary
The legacy dataset contains phone numbers from multiple countries, written in inconsistent formats and without reliable country codes or numbering standards.
Because of this, any attempt to standardize or validate phone numbers would introduce assumptions the data cannot support and risk altering real customer information.

The redesigned schema therefore preserves phone numbers exactly as they appear in the source system.
This approach prioritizes data fidelity, avoids false precision, and keeps the contact information honest and transparent for analytical use.

## Schema Design
The redesigned schema stores phone numbers as simple text fields:
* `customer_phone` (required)
* `customer_fax` (optional)
* `employee_phone` (required)
* `employee_fax` (optional)

All phone fields use VARCHAR(255) and include a basic check to ensure they are not blank.  
No additional constraints like uniqueness, formatting rules or validations are applied.

This design reflects the reality that:
* phone numbers change frequently
* they may be shared (family, office, department lines)
* formatting varies widely between countries
* the legacy dataset does not provide enough information to standardize them safely

Attempting to enforce strict formatting or rewrite numbers using a specific standard would require assumptions the dataset cannot support.

## Why Phone Numbers Are Not Normalized
Several factors make normalization impractical and potentially misleading:

**1. International Variation**  
The dataset includes numbers from North America, Europe, Australia and other regions.  
Without reliable country metadata, it is impossible to apply a consistent formatting rule.

**2. Lack of Context**  
The legacy data does not include:
* country codes for all records
* region‑specific numbering rules
* information indicating whether numbers are mobile, landline, or office extensions

**3. Not Used as Identifiers**  
Unlike email addresses, phone numbers are not used as unique identifiers in this project.  
They are simply contact fields. Enforcing uniqueness or strict validation would create unnecessary constraints.

**4. Avoiding False Precision**  
Normalizing phone numbers without complete information can create the illusion of accuracy while actually introducing errors.  
Preserving the original values avoids this problem entirely.

## Migration Details
During migration from the legacy database, one customer record lacked a phone number.  
Because the redesigned schema requires every customer and employee to have a phone value, this created a conflict.

To resolve this without deleting data or inventing a misleading format, the migration assigns a clear, deterministic placeholder (`0000000000`).

This placeholder:
* preserves the customer record
* satisfies the `NOT NULL` constraint
* avoids using ambiguous values like “UNKNOWN”
* makes the missing data easy to identify later
* reflects common ETL practice for incomplete legacy data

In a real business system, a missing phone number would normally trigger a follow‑up process  
to collect the correct information (for example contacting the customer via email).  
For this project, the placeholder provides a clean and fully documented solution.

## Summary
The phone number design prioritizes data fidelity, simplicity, and practicality:
* Original values are preserved exactly as stored
* Required fields remain required
* No artificial formatting or validation is imposed
* Migration handles missing data safely and transparently

This approach ensures that the migrated database remains strict, predictable, and honest about the limitations of the legacy dataset.
