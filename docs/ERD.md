# Entity Relationship Diagram

ERD for the Procurement database.

## Overview

This document describes the entity relationships in the Procurement database.

## Current Tables

```
┌─────────────────┐
│ schema_migrations│
├─────────────────┤
│ version (PK)    │
│ description     │
│ applied_at      │
└─────────────────┘

┌─────────────────┐
│   countries     │
├─────────────────┤
│ code (PK)       │
│ name            │
│ name_fr         │
│ alpha2 (UQ)     │
│ region          │
│ subregion       │
└─────────────────┘
        ▲
        │
        │ FK: country
┌─────────────────┐
│   suppliers     │
├─────────────────┤
│ id (PK)         │
│ code (UQ)       │
│ name            │
│ email           │
│ phone           │
│ address         │
│ city            │
│ country (FK)    │
│ status          │
│ created_at      │
│ updated_at      │
│ created_by      │
│ updated_by      │
└─────────────────┘

┌─────────────────┐
│   currencies    │
├─────────────────┤
│ code (PK)       │
│ name            │
│ symbol          │
│ decimal_places  │
└─────────────────┘

┌─────────────────┐
│ order_statuses  │
├─────────────────┤
│ code (PK)       │
│ label           │
│ label_fr        │
│ description     │
│ sort_order      │
│ is_active       │
│ color           │
└─────────────────┘
```

## Relationships

### suppliers → countries
- **Type**: Many-to-One
- **Foreign Key**: suppliers.country → countries.code
- **Action**: ON DELETE SET NULL
- **Description**: Each supplier is located in a country

## Planned Tables

The following tables are planned for future implementation:

- purchase_orders (references suppliers, currencies, order_statuses)
- order_items (references purchase_orders)
- goods_receipts (references purchase_orders, suppliers)
- receipt_items (references goods_receipts, order_items)
- vendor_invoices (references suppliers, currencies, purchase_orders)
- invoice_items (references vendor_invoices, order_items)

## Cardinality Notation

- `1` : One
- `*` : Many
- `0..1` : Zero or One
- `0..*` : Zero or Many
- `1..*` : One or Many

## Related Documentation

- [Schema Reference](./schema.md)
- [Database Design](./DATABASE_DESIGN.md)
- [Data Dictionary](./DATA_DICTIONARY.md)
