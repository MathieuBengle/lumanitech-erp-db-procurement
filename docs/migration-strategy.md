# Migration Strategy

This document describes the migration strategy for the Procurement database.

## Overview

The Procurement database uses a **forward-only migration strategy**. This means:

- Migrations are applied sequentially in one direction only (forward)
- There are no rollback scripts
- Errors are corrected by creating new forward migrations
- Once applied to production, migrations are immutable

## Why Forward-Only?

### Advantages

✅ **Simplicity**: No need to write and maintain rollback scripts
✅ **Safety**: Prevents accidental data loss from rollbacks
✅ **Traceability**: Complete history of all schema changes
✅ **Production-Ready**: Reflects real-world production constraints
✅ **Consistency**: Single path of schema evolution

### Trade-offs

⚠️ **Error Correction**: Requires new migration instead of rollback
⚠️ **Testing**: More important to test thoroughly before applying

## Migration Naming Convention

Migrations follow the format: `V###_description.sql`

Where:
- `V` = Version prefix (required)
- `###` = Three-digit sequential number (001, 002, 003, ...)
- `description` = Brief description in snake_case (English)

### Valid Examples

```
V001_init_schema.sql
V002_add_suppliers_table.sql
V003_add_purchase_orders.sql
V004_add_audit_columns.sql
```

### Invalid Examples

```
001_init.sql                    # Missing V prefix
V1_init.sql                     # Number must be 3 digits
V001-init-schema.sql           # Use underscore, not dash
V001__init_schema.sql          # Double underscore not allowed
V001_init_schema_rollback.sql  # No rollback files
20231215_init.sql              # No timestamps
```

## Migration Structure

Every migration must follow this structure:

```sql
-- Migration: V###_description
-- Created: YYYY-MM-DD
-- Author: Your Name
-- Description: Detailed explanation of what this migration does

START TRANSACTION;

-- Your SQL changes here
-- Use IF NOT EXISTS for idempotency

-- Record migration
INSERT INTO schema_migrations (version, description) 
VALUES ('V###', 'description')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;

COMMIT;
```

## Schema Migrations Table

The `schema_migrations` table tracks which migrations have been applied:

```sql
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(50) PRIMARY KEY,
    description VARCHAR(255),
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_applied_at (applied_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Every migration must insert its own record:**

```sql
INSERT INTO schema_migrations (version, description) 
VALUES ('V002', 'add_suppliers_table')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

## Migration Rules

### 1. Immutability

Once merged to `main`, a migration **must never be modified**.

❌ **Wrong**: Edit `V001_init_schema.sql` after merge
✅ **Right**: Create `V006_fix_init_schema.sql`

### 2. Sequential Numbering

Migrations must be numbered sequentially without gaps.

- Always use the next available number
- No duplicate version numbers
- No skipped numbers

### 3. Idempotency

Use `IF NOT EXISTS` and `IF EXISTS` to allow re-running migrations:

```sql
-- ✅ Good - can be run multiple times
CREATE TABLE IF NOT EXISTS my_table (...);
ALTER TABLE my_table ADD COLUMN IF NOT EXISTS my_column VARCHAR(100);

-- ❌ Bad - will fail on second run
CREATE TABLE my_table (...);
```

### 4. Self-Tracking

Every migration must insert into `schema_migrations`:

```sql
INSERT INTO schema_migrations (version, description) 
VALUES ('V002', 'add_suppliers_table')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

### 5. No Rollbacks

Forward-only means:
- ❌ No `*_down.sql` files
- ❌ No `*_rollback.sql` files
- ✅ Corrections via new migrations

## Migration Workflow

### Creating a Migration

```bash
# 1. Check the last migration number
cd migrations
ls -1 V*.sql | tail -1
# Output: V005_create_views.sql

# 2. Create next migration
touch V006_add_contracts_table.sql

# 3. Edit using TEMPLATE.sql as guide

# 4. Test locally
mysql -u admin -p lumanitech_erp_procurement < V006_add_contracts_table.sql

# 5. Validate
cd ..
./scripts/validate.sh

# 6. Commit
git add migrations/V006_add_contracts_table.sql
git commit -m "feat: add contracts table migration"
```

### Applying Migrations

Use the `apply-migrations.sh` script:

```bash
./scripts/apply-migrations.sh --login-path=local --database=lumanitech_erp_procurement
```

Or the full deployment script:

```bash
./scripts/deploy.sh --login-path=local
```

### Handling Errors

#### Error During Development

If a migration fails during local testing:

```bash
# 1. Restore from backup
mysql -u admin -p lumanitech_erp_procurement < backup.sql

# 2. Fix the migration file
# Edit V006_add_contracts_table.sql

# 3. Re-test
mysql -u admin -p lumanitech_erp_procurement < V006_add_contracts_table.sql
```

#### Error After Merge

If an error is found after merge to `main`:

```sql
-- Create V007_fix_contracts_table.sql

START TRANSACTION;

-- Fix the problem from V006
ALTER TABLE contracts 
ADD COLUMN IF NOT EXISTS missing_column VARCHAR(100);

INSERT INTO schema_migrations (version, description) 
VALUES ('V007', 'fix_contracts_table');

COMMIT;
```

## Common Migration Patterns

### Adding a Table

```sql
-- Migration: V002_add_suppliers_table

START TRANSACTION;

CREATE TABLE IF NOT EXISTS suppliers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_code (code),
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Supplier master data';

INSERT INTO schema_migrations (version, description) 
VALUES ('V002', 'add_suppliers_table');

COMMIT;
```

### Adding a Column

```sql
-- Migration: V003_add_email_to_suppliers

START TRANSACTION;

ALTER TABLE suppliers 
ADD COLUMN IF NOT EXISTS email VARCHAR(255) 
AFTER name;

INSERT INTO schema_migrations (version, description) 
VALUES ('V003', 'add_email_to_suppliers');

COMMIT;
```

### Adding an Index

```sql
-- Migration: V004_add_supplier_indexes

START TRANSACTION;

CREATE INDEX IF NOT EXISTS idx_suppliers_email 
ON suppliers(email);

INSERT INTO schema_migrations (version, description) 
VALUES ('V004', 'add_supplier_indexes');

COMMIT;
```

### Inserting Reference Data

```sql
-- Migration: V005_add_order_statuses

START TRANSACTION;

INSERT IGNORE INTO order_statuses (code, label, sort_order) VALUES
('draft', 'Draft', 1),
('submitted', 'Submitted', 2),
('approved', 'Approved', 3);

INSERT INTO schema_migrations (version, description) 
VALUES ('V005', 'add_order_statuses');

COMMIT;
```

## Best Practices

### 1. Test Thoroughly

```bash
# Always test locally first
mysqldump --login-path=local lumanitech_erp_procurement > backup.sql
mysql --login-path=local lumanitech_erp_procurement < V006_new_migration.sql
# Verify result
# Restore if needed: mysql --login-path=local lumanitech_erp_procurement < backup.sql
```

### 2. Use Transactions

```sql
START TRANSACTION;
-- Your changes
COMMIT;
```

### 3. Document Well

```sql
-- Migration: V006_add_contracts_table
-- Created: 2024-12-23
-- Author: Procurement Team
-- Description: Add contracts table for long-term supplier agreements.
--              Includes contract number, dates, status, and value.
--              Foreign key to suppliers table.
```

### 4. Make Incremental Changes

For complex changes, create multiple smaller migrations:

```sql
-- V010_prepare_column_rename.sql - Add new column
-- V011_migrate_data.sql - Copy data
-- V012_complete_rename.sql - Drop old column
```

### 5. Validate

```bash
# Run validation before committing
./scripts/validate.sh
```

## Deployment

### Development

```bash
./scripts/deploy.sh --login-path=local --with-seeds
```

### Staging

```bash
# Backup first
mysqldump --host=staging-db.example.com lumanitech_erp_procurement > backup.sql

# Deploy
./scripts/deploy.sh --host=staging-db.example.com --database=lumanitech_erp_procurement

# Verify
mysql --host=staging-db.example.com lumanitech_erp_procurement -e "SELECT * FROM schema_migrations ORDER BY version;"
```

### Production

```bash
# 1. Backup
mysqldump --host=prod-db.example.com lumanitech_erp_procurement > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Deploy (NO SEEDS!)
./scripts/deploy.sh --host=prod-db.example.com --database=lumanitech_erp_procurement

# 3. Verify
mysql --host=prod-db.example.com lumanitech_erp_procurement -e "SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5;"
```

## Troubleshooting

### Migration Already Applied

This is normal and safe. The `ON DUPLICATE KEY UPDATE` ensures idempotency.

### Migration Failed Mid-Way

If a migration partially completes:

1. Assess the damage
2. Manually fix if possible
3. Create a corrective migration
4. Document what happened

### Version Number Conflict

If two PRs create the same version number:

1. First PR merged keeps its number
2. Second PR must renumber:
   ```bash
   git mv migrations/V010_feature_b.sql migrations/V011_feature_b.sql
   # Update version in file content
   # Update schema_migrations insert
   ```

## Related Documentation

- [Migration Template](../migrations/TEMPLATE.sql)
- [Migrations README](../migrations/README.md)
- [Schema Documentation](./schema.md)
- [Scripts Guide](../scripts/README.md)
