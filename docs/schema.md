# Schema Documentation

Database schema documentation for the Procurement module of Lumanitech ERP.

## Overview

The Procurement database (`lumanitech_erp_procurement`) manages:
- Supplier information
- Purchase orders
- Goods receipts
- Vendor invoices
- Reference data (countries, currencies, statuses)

## Database Information

- **Database Name**: `lumanitech_erp_procurement`
- **Character Set**: `utf8mb4`
- **Collation**: `utf8mb4_unicode_ci`
- **Engine**: InnoDB
- **Owner**: Procurement API (`lumanitech-erp-api-procurement`)

## Schema Structure

The schema is organized into subdirectories:

```
schema/
├── tables/       # Table definitions
├── views/        # SQL views
├── procedures/   # Stored procedures
├── functions/    # SQL functions
├── triggers/     # Database triggers
└── indexes/      # Standalone index definitions
```

**Naming conventions:**
- procedures: `sp_<name>.sql`
- triggers: `trg_<name>.sql`

## Core Tables

### schema_migrations

Tracks applied database migrations.

**Columns:**
- `version` (VARCHAR(50), PK): Migration version (e.g., 'V001', 'V002')
- `description` (VARCHAR(255)): Migration description
- `applied_at` (TIMESTAMP): When migration was applied

**Indexes:**
- Primary Key on `version`
- Index on `applied_at`

**Purpose:**
- Self-tracking for migration system
- Every migration inserts its own record
- Prevents duplicate migrations

### countries

ISO 3166-1 country codes.

**Columns:**
- `code` (VARCHAR(3), PK): ISO 3166-1 alpha-3 code (e.g., 'USA', 'FRA')
- `name` (VARCHAR(100)): Country name in English
- `name_fr` (VARCHAR(100)): Country name in French
- `alpha2` (VARCHAR(2), UNIQUE): ISO 3166-1 alpha-2 code
- `region` (VARCHAR(50)): Geographic region
- `subregion` (VARCHAR(50)): Geographic subregion

**Indexes:**
- Primary Key on `code`
- Unique index on `alpha2`
- Index on `name`
- Index on `region`

**Purpose:**
- Reference data for country selection
- Used in supplier addresses
- Standardized country codes

### currencies

ISO 4217 currency codes.

**Columns:**
- `code` (VARCHAR(3), PK): ISO 4217 code (e.g., 'USD', 'EUR')
- `name` (VARCHAR(50)): Currency name
- `symbol` (VARCHAR(10)): Currency symbol (e.g., '$', '€')
- `decimal_places` (TINYINT): Number of decimal places (default: 2)

**Indexes:**
- Primary Key on `code`
- Index on `name`

**Purpose:**
- Reference data for currency selection
- Used in purchase orders and invoices
- Multi-currency support

### order_statuses

Purchase order status codes.

**Columns:**
- `code` (VARCHAR(50), PK): Status code
- `label` (VARCHAR(100)): Status label in English
- `label_fr` (VARCHAR(100)): Status label in French
- `description` (TEXT): Detailed description
- `sort_order` (INT): Display order
- `is_active` (BOOLEAN): Whether status is active
- `color` (VARCHAR(20)): UI color code

**Indexes:**
- Primary Key on `code`
- Index on `sort_order`

**Purpose:**
- Workflow status tracking
- UI display and filtering
- Internationalization support

**Standard Statuses:**
- `draft`: Order being created
- `submitted`: Awaiting approval
- `approved`: Ready to send
- `sent`: Sent to supplier
- `confirmed`: Confirmed by supplier
- `partial`: Partially received
- `received`: Fully received
- `rejected`: Rejected
- `cancelled`: Cancelled

### suppliers

Supplier master data.

**Columns:**
- `id` (BIGINT UNSIGNED, PK, AUTO_INCREMENT): Unique identifier
- `code` (VARCHAR(50), UNIQUE): Supplier code (e.g., 'SUP-001')
- `name` (VARCHAR(255)): Supplier name
- `email` (VARCHAR(255)): Contact email
- `phone` (VARCHAR(50)): Contact phone
- `address` (TEXT): Street address
- `city` (VARCHAR(100)): City
- `country` (VARCHAR(3), FK): Country code (references countries.code)
- `status` (ENUM): 'active', 'inactive', 'blocked'
- `created_at` (TIMESTAMP): Creation timestamp
- `updated_at` (TIMESTAMP): Last update timestamp
- `created_by` (BIGINT UNSIGNED): User who created the record
- `updated_by` (BIGINT UNSIGNED): User who last updated the record

**Indexes:**
- Primary Key on `id`
- Unique index on `code`
- Index on `name`
- Index on `status`
- Composite index on `(city, country)`

**Foreign Keys:**
- `country` → `countries(code)` ON DELETE SET NULL

**Purpose:**
- Central supplier registry
- Contact information
- Address management
- Status tracking for supplier lifecycle

**Business Rules:**
- Supplier code must be unique
- Status controls supplier availability
- Audit columns track changes

## Future Tables

The following tables are planned for future migrations:

### purchase_orders

Purchase order header information.

**Planned Columns:**
- Order number, supplier reference
- Status, dates, amounts
- Currency, payment terms
- Audit columns

### order_items

Purchase order line items.

**Planned Columns:**
- Order reference, line number
- Product/service description
- Quantity, unit price, total
- Delivery information

### goods_receipts

Receipt of goods from suppliers.

**Planned Columns:**
- Receipt number, order reference
- Receipt date, received by
- Status, notes
- Audit columns

### receipt_items

Goods receipt line items.

**Planned Columns:**
- Receipt reference, line number
- Order item reference
- Quantity received
- Quality inspection results

### vendor_invoices

Invoices received from suppliers.

**Planned Columns:**
- Invoice number, supplier reference
- Order reference, receipt reference
- Invoice date, due date, amounts
- Payment status
- Audit columns

### invoice_items

Vendor invoice line items.

**Planned Columns:**
- Invoice reference, line number
- Description, quantity, amounts
- Tax information
- Order/receipt item references

## Data Types

### Standard Patterns

**Primary Keys:**
```sql
id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
```

**Audit Timestamps:**
```sql
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```

**Audit Users:**
```sql
created_by BIGINT UNSIGNED,
updated_by BIGINT UNSIGNED
```

**Unique Codes:**
```sql
code VARCHAR(50) UNIQUE NOT NULL
```

**Amounts:**
```sql
amount DECIMAL(15,2)  -- For monetary values
quantity DECIMAL(10,3) -- For quantities
```

## Naming Conventions

### Tables
- Lowercase
- Plural nouns
- Snake_case
- Examples: `suppliers`, `purchase_orders`, `order_items`

### Columns
- Lowercase
- Snake_case
- Descriptive names
- Examples: `created_at`, `unit_price`, `order_number`

### Indexes
- Prefix: `idx_`
- Table name + column(s)
- Examples: `idx_suppliers_code`, `idx_orders_status`

### Foreign Keys
- Prefix: `fk_`
- Child table + parent table
- Examples: `fk_orders_suppliers`, `fk_items_orders`

## Foreign Key Strategy

### Referential Actions

**ON DELETE:**
- `RESTRICT`: For critical references (orders → suppliers)
- `CASCADE`: For dependent data (order items → orders)
- `SET NULL`: For optional references (suppliers → countries)

**ON UPDATE:**
- Generally `CASCADE` for natural keys
- Not needed for surrogate keys (rarely updated)

### Current Foreign Keys

```sql
-- Suppliers reference countries
ALTER TABLE suppliers
ADD CONSTRAINT fk_suppliers_countries
FOREIGN KEY (country) REFERENCES countries(code)
ON DELETE SET NULL;
```

## Indexes

### Index Strategy

- Primary keys are automatically indexed
- Unique constraints create unique indexes
- Foreign keys should have indexes
- Queries determine additional indexes

### Current Indexes

**suppliers:**
- PK: `id`
- Unique: `code`
- Regular: `name`, `status`, `(city, country)`

**countries:**
- PK: `code`
- Unique: `alpha2`
- Regular: `name`, `region`

**currencies:**
- PK: `code`
- Regular: `name`

**order_statuses:**
- PK: `code`
- Regular: `sort_order`

## Character Sets and Collation

**Database Level:**
```sql
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
```

**Why utf8mb4:**
- Full Unicode support (including emojis)
- 4-byte UTF-8 characters
- International character support

**Why utf8mb4_unicode_ci:**
- Case-insensitive comparison
- Accent-insensitive comparison
- Better international sorting

## Storage Engine

**InnoDB** is used for all tables:

**Advantages:**
- ACID compliance
- Foreign key support
- Row-level locking
- Crash recovery
- Transaction support

## Schema Evolution

### Migration System

Schema changes are managed through versioned migrations:

1. All changes go through migrations
2. Migrations are forward-only
3. Each migration is tracked in `schema_migrations`
4. Schema files in `schema/` reflect current state

### Adding New Tables

1. Create migration: `V###_add_new_table.sql`
2. Define table in migration
3. After merge, add to `schema/tables/`

### Modifying Tables

1. Create migration: `V###_modify_table.sql`
2. Use `ALTER TABLE` statements
3. Update corresponding file in `schema/tables/`

## Best Practices

### Table Design

✅ **Do:**
- Use InnoDB engine
- Define primary keys
- Add indexes for foreign keys
- Include audit columns (created_at, updated_at)
- Use appropriate data types
- Add comments to tables and complex columns

❌ **Don't:**
- Use MyISAM engine
- Create tables without primary keys
- Over-index (impacts write performance)
- Use TEXT for short strings
- Use CHAR for variable-length data

### Column Design

✅ **Do:**
- Use NOT NULL with DEFAULT when appropriate
- Use ENUM for fixed small sets
- Use DECIMAL for monetary amounts
- Use TIMESTAMP for dates with time
- Use VARCHAR with appropriate length

❌ **Don't:**
- Make everything nullable
- Use FLOAT/DOUBLE for money
- Use DATETIME without timezone consideration
- Use VARCHAR(255) for everything

### Index Design

✅ **Do:**
- Index foreign keys
- Index columns used in WHERE clauses
- Index columns used in JOIN conditions
- Use composite indexes for multi-column queries
- Monitor and optimize based on actual usage

❌ **Don't:**
- Index every column
- Create duplicate indexes
- Ignore index maintenance
- Index small tables

## Related Documentation

- [Migration Strategy](./migration-strategy.md)
- [Data Dictionary](./data-dictionary.md)
- [Schema Design](./schema-design.md)
- [Scripts Guide](../scripts/README.md)

## Maintenance

### Schema Validation

```bash
# Validate migrations
./scripts/validate.sh

# Check current schema
mysql --login-path=local lumanitech_erp_procurement -e "SHOW TABLES;"

# View table structure
mysql --login-path=local lumanitech_erp_procurement -e "DESCRIBE suppliers;"
```

### Migration History

```sql
-- View all applied migrations
SELECT * FROM schema_migrations ORDER BY version;

-- View recent migrations
SELECT * FROM schema_migrations ORDER BY applied_at DESC LIMIT 10;

-- Check specific migration
SELECT * FROM schema_migrations WHERE version = 'V001';
```
