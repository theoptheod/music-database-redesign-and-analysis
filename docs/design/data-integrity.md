# Data Integrity - Design Notes

## Summary
The redesigned schema implements a strict, audit‑safe deletion model to ensure that financial records remain immutable for the lifetime of the system.
Because entities such as `invoice` and `invoice_line` represent real financial transactions, the database must guarantee that no sequence of operations,  
no matter the reason (e.g. user error, ORM misconfiguration, cascading deletes), can ever remove or corrupt data that are part of the financial audit trail.

To achieve this, the schema uses a `RESTRICT` deletion strategy, combined with carefully controlled SQLAlchemy relationship settings.  
This prevents all deletes in order to preserve historical accuracy and protect analytical integrity.

## 1.Core Principle: Financial Records Must Be Immutable
The `invoice_line` table is the foundation of the financial audit chain.  
Through the financial audit chain we record:
* which track was sold
* at what price
* in what quantity
* on which invoice
* to which customer
* represented by which employee

Because these records represent real financial transactions, they must remain intact for the lifetime of the system.

This leads to the first rule:

No table that participates directly or indirectly in the financial audit chain may ever be deleted automatically.

This includes:
* `invoice_line`
* `invoice`
* `customer`
* `employee`
* `track`

## 2. Why use `RESTRICT`
In order to preserve the necessary data every foreign key in the schema uses:
```
ondelete="RESTRICT"
```
This means:
* A parent row cannot be deleted if any child rows reference it.
* The database, not SQLAlchemy, enforces this rule.
* Accidental deletes are impossible.

This is the safest possible deletion model for financial data.

## 3.Why `passive_deletes=True` Is Required

This setting:
```
passive_deletes=True
```
prevents SQLAlchemy from deleting related rows and allows the database to enforce `RESTRICT`.

It guarantees that the ORM cannot bypass the database’s safety rules.

## 4. Why Cascades Are Explicitly Disabled
Every relationship in the schema uses:
```
cascade="save-update, merge"
```

This minimal cascade set allows:
* updating related objects
* merging session state

But explicitly prevents:
* deleting children
* deleting parents
* orphan deletes
* cascading through relationship chains

This prevents ORM‑level data loss.

## 5.The Audit Chain and How `RESTRICT` Protects It
Here is the full dependency chain:
```
Track -> InvoiceLine -> Invoice -> Customer -> Employee -> Address -> City -> AdministrativeDivision -> PostalZipCode -> Country
```

RESTRICT ensures:
* You cannot delete a Track if it appears on any InvoiceLine
* You cannot delete an Invoice if it has InvoiceLines
* You cannot delete a Customer if they have Invoices
* You cannot delete an Employee if they represent Customers
* You cannot delete an Address used by Customers or Employees
* You cannot delete a City if it has Addresses
* You cannot delete an AdministrativeDivision with a City
* You cannot delete a Country with Cities or Postal Codes

This creates a deletion‑proof chain that preserves all financial history.

## 6.Why This Matters
This design ensures:
* Regulatory compliance
* Historical accuracy
* Protection against developer mistakes
* Protection against ORM misconfiguration
* Protection against accidental cascading deletes
* Long‑term data integrity

The schema is intentionally designed so that nothing in the financial audit chain can ever be deleted.  
This is the correct and safe approach for any system that handles real transactions.
