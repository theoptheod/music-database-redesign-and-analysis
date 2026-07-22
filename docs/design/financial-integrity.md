# Financial Integrity - Design Notes

## Summary
This document outlines how the created financial subsystem of the database preserves historical accuracy and prevents data loss.  
It explains the immutability of invoices, the protection of tracks and customers through `RESTRICT` constraints,
and the relationships that anchor financial records to catalog and employee data.
It also details the prevention of cascading deletes, strict constraints and stable reporting.
Together, these rules ensure a fully audit‑safe and deletion‑protected financial architecture.

### Key Principles
* Invoices are immutable and once created, their billing fields remain fixed, even if the customer later changes address or country.
* Tracks cannot be deleted if they appear in any invoice line.
* Customers cannot be deleted if they have invoices.
* Employees cannot be deleted if they represent customers with invoices.

### Entities Involved
* `invoice`: Stores denormalized billing details and links to a customer.
* `invoice_line`: Stores purchased track information, quantity, and pricing.
* `track`: Cannot be removed once referenced by any invoice line.
* `customer`: Cannot be removed while invoices exist.
* `employee`: Cannot be removed while representing customers with invoices.

### Integrity Guarantees
* `RESTRICT` prevents deletion of any financial entity that would break historical records.
* No cascading deletes ensure invoice history is never lost.
* Check constraints enforce valid pricing, quantity, and non‑empty billing fields.
* Indexes support efficient financial reporting and analytics.
