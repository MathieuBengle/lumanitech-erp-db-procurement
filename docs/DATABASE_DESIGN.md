# Database Design

Design documentation for the Procurement database.

## Overview

The Procurement database manages supplier information, purchase orders, goods receipts, and vendor invoices for the Lumanitech ERP system.

## Database Name

`lumanitech_erp_procurement`

## Design Principles

1. **Normalization**: Tables are normalized to 3NF to minimize redundancy
2. **Referential Integrity**: Foreign keys ensure data consistency
3. **Audit Trail**: All tables include created_at/updated_at timestamps
4. **UTF-8 Support**: Full Unicode support with utf8mb4 character set
5. **InnoDB Engine**: ACID compliance and foreign key support

## Schema Organization

The schema is organized into subdirectories:

- `tables/`: Core data tables
- `views/`: SQL views for reporting
- `procedures/`: Stored procedures (sp_*)
- `functions/`: SQL functions
- `triggers/`: Database triggers (trg_*)
- `indexes/`: Standalone index definitions

## Key Tables

### Reference Data
- `countries`: ISO 3166-1 country codes
- `currencies`: ISO 4217 currency codes
- `order_statuses`: Purchase order status codes

### Core Business Tables
- `suppliers`: Supplier master data
- `purchase_orders`: Purchase order headers (planned)
- `order_items`: Purchase order line items (planned)
- `goods_receipts`: Goods receipt headers (planned)
- `receipt_items`: Goods receipt line items (planned)
- `vendor_invoices`: Vendor invoice headers (planned)
- `invoice_items`: Vendor invoice line items (planned)

### System Tables
- `schema_migrations`: Migration tracking

## Data Types Standards

- Primary Keys: `BIGINT UNSIGNED AUTO_INCREMENT`
- Codes: `VARCHAR(50)`
- Names: `VARCHAR(255)`
- Amounts: `DECIMAL(15,2)`
- Timestamps: `TIMESTAMP DEFAULT CURRENT_TIMESTAMP`
- Booleans: `BOOLEAN` (TINYINT(1))

## Naming Conventions

- Tables: lowercase, plural, snake_case
- Columns: lowercase, snake_case
- Procedures: `sp_<name>.sql`
- Triggers: `trg_<name>.sql`
- Indexes: `idx_<table>_<column(s)>`
- Foreign Keys: `fk_<child>_<parent>`

## Migration Strategy

See [migration-strategy.md](./migration-strategy.md) for details on the forward-only migration approach.

## Related Documentation

- [Schema Reference](./schema.md)
- [Data Dictionary](./DATA_DICTIONARY.md)
- [ERD](./ERD.md)
