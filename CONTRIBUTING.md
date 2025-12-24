# Contributing to Procurement Database

Thank you for contributing to the Lumanitech ERP Procurement database repository!

This document provides guidelines for contributing database schema changes, migrations, and related improvements.

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Migration Guidelines](#migration-guidelines)
- [Pull Request Process](#pull-request-process)
- [Code Standards](#code-standards)
- [Testing](#testing)

## Getting Started

### Prerequisites

- MySQL 8.0+ client
- Git
- Access to a local MySQL instance
- Familiarity with SQL and database design

### Initial Setup

1. **Fork and clone the repository:**

```bash
git clone https://github.com/MathieuBengle/lumanitech-erp-db-procurement.git
cd lumanitech-erp-db-procurement
```

2. **Set up MySQL credentials:**

```bash
mysql_config_editor set --login-path=local \
    --host=localhost \
    --user=admin \
    --password
```

3. **Deploy the database locally:**

```bash
./scripts/deploy.sh --login-path=local --with-seeds
```

4. **Verify setup:**

```bash
mysql --login-path=local lumanitech_erp_procurement -e "SELECT * FROM schema_migrations;"
```

## Development Workflow

### Creating a Feature Branch

Always create a new branch for your changes:

```bash
git checkout -b feat/migration-XXX-description
```

Branch naming conventions:
- `feat/migration-XXX-description` - New migration
- `fix/migration-XXX-description` - Migration fix
- `docs/update-documentation` - Documentation updates
- `chore/update-scripts` - Script maintenance

### Making Changes

1. **For schema changes**: Create a new migration
2. **For documentation**: Update relevant `.md` files
3. **For scripts**: Update and test shell scripts

### Committing Changes

Follow conventional commit format:

```bash
git commit -m "feat: add purchase orders table migration"
git commit -m "fix: correct suppliers table foreign key"
git commit -m "docs: update migration strategy guide"
git commit -m "chore: update deployment script"
```

Commit message format:
- `feat:` - New feature or migration
- `fix:` - Bug fix or correction
- `docs:` - Documentation changes
- `chore:` - Maintenance tasks
- `test:` - Test-related changes

## Migration Guidelines

### Naming Convention

Migrations must follow: `V###_description.sql`

- `V` = Version prefix (required)
- `###` = Three-digit sequential number (001, 002, 003...)
- `description` = Brief snake_case description

**Examples:**
```
V001_init_schema.sql          ✅
V002_add_suppliers_table.sql  ✅
V003_add_email_column.sql     ✅

001_init.sql                  ❌ Missing V prefix
V1_init.sql                   ❌ Number must be 3 digits
V001__init.sql                ❌ No double underscores
```

### Creating a Migration

1. **Determine the next version number:**

```bash
cd migrations
ls -1 V*.sql | tail -1
# Output: V001_init_schema.sql
# Next: V002
```

2. **Create the migration file:**

```bash
touch V002_add_purchase_orders.sql
```

3. **Use the template:**

```bash
# Copy template structure
cp TEMPLATE.sql V002_add_purchase_orders.sql
# Edit the file
```

4. **Follow the template structure:**

```sql
-- Migration: V002_add_purchase_orders
-- Created: 2024-12-23
-- Author: Your Name
-- Description: Add purchase orders table for managing supplier orders

START TRANSACTION;

-- Your changes here
CREATE TABLE IF NOT EXISTS purchase_orders (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    -- ... other columns
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Record migration
INSERT INTO schema_migrations (version, description) 
VALUES ('V002', 'add_purchase_orders')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;

COMMIT;
```

### Migration Best Practices

✅ **Do:**
- Use `IF NOT EXISTS` for idempotency
- Include comprehensive comments
- Use transactions (`START TRANSACTION` / `COMMIT`)
- Test thoroughly before committing
- Record migration in `schema_migrations`
- Follow naming conventions
- Keep migrations focused and atomic

❌ **Don't:**
- Modify existing migrations after merge
- Create rollback files (`*_down.sql`)
- Skip version numbers
- Include sensitive data
- Use database-specific features without consideration
- Make migrations that can't be replayed

### Testing Migrations

1. **Backup your database:**

```bash
mysqldump --login-path=local lumanitech_erp_procurement > backup.sql
```

2. **Apply the migration:**

```bash
mysql --login-path=local lumanitech_erp_procurement < migrations/V002_add_purchase_orders.sql
```

3. **Verify the changes:**

```bash
mysql --login-path=local lumanitech_erp_procurement -e "DESCRIBE purchase_orders;"
mysql --login-path=local lumanitech_erp_procurement -e "SELECT * FROM schema_migrations WHERE version='V002';"
```

4. **Test application compatibility** (if applicable)

5. **Restore if needed:**

```bash
mysql --login-path=local lumanitech_erp_procurement < backup.sql
```

### Validation

Before committing, always run:

```bash
./scripts/validate.sh
```

This checks:
- Migration naming conventions
- Sequential numbering
- SQL syntax
- Best practices compliance

## Pull Request Process

### Before Creating a PR

1. ✅ Migrations tested locally
2. ✅ Validation scripts pass (`./scripts/validate.sh`)
3. ✅ Documentation updated (if needed)
4. ✅ Commit messages follow conventions
5. ✅ No sensitive data in migrations

### PR Description Template

```markdown
## Description
Brief description of the changes

## Migration Details
- Migration number: V002
- Purpose: Add purchase orders table
- Dependencies: Requires V001

## Testing
- [ ] Tested on fresh database
- [ ] Tested with existing data
- [ ] Validated with ./scripts/validate.sh
- [ ] Application tested (if applicable)

## Checklist
- [ ] Migration follows naming convention
- [ ] Migration is idempotent
- [ ] Migration records itself in schema_migrations
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

### Review Process

PRs require:
- ✅ At least one approval
- ✅ All CI checks passing
- ✅ No merge conflicts
- ✅ Up-to-date with main branch

## Code Standards

### SQL Style

**Formatting:**
```sql
-- Keywords in UPPERCASE
CREATE TABLE IF NOT EXISTS table_name (
    -- Columns indented
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    -- Constraints clearly separated
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Naming:**
- Tables: `snake_case`, plural (`suppliers`, `purchase_orders`)
- Columns: `snake_case` (`created_at`, `order_number`)
- Indexes: `idx_table_column` (`idx_suppliers_code`)
- Foreign Keys: `fk_child_parent` (`fk_orders_suppliers`)

**Data Types:**
- Use `BIGINT UNSIGNED` for IDs
- Use `VARCHAR` for variable-length strings
- Use `DECIMAL(15,2)` for currency
- Use `TIMESTAMP` for dates with time
- Use `ENUM` for small fixed sets

**Required Elements:**
- Primary keys on all tables
- Indexes on foreign keys
- Audit columns (`created_at`, `updated_at`)
- Comments on tables and complex columns

### Documentation

**Migration Headers:**
```sql
-- Migration: V###_description
-- Created: YYYY-MM-DD
-- Author: Your Name
-- Description: Detailed explanation of the migration
```

**Code Comments:**
```sql
-- Section headers for organization
-- ============================================================================
-- Reference Data Tables
-- ============================================================================

-- Inline comments for complex logic
ALTER TABLE suppliers 
ADD COLUMN status ENUM('active', 'inactive', 'blocked') DEFAULT 'active'
COMMENT 'Supplier lifecycle status';
```

## Testing

### Local Testing

```bash
# Full deployment test
./scripts/deploy.sh --login-path=local --with-seeds

# Validation test
./scripts/validate.sh

# Migration-only test
./scripts/apply-migrations.sh --login-path=local --database=lumanitech_erp_procurement
```

### Test Cases

For new migrations, verify:
1. ✅ Migration applies successfully on empty database
2. ✅ Migration is idempotent (can be run multiple times)
3. ✅ Migration records itself in `schema_migrations`
4. ✅ Foreign keys work correctly
5. ✅ Indexes are created
6. ✅ Default values work as expected
7. ✅ Application can read/write data

## Repository-Specific Information

### Repository
- **Name**: `lumanitech-erp-db-procurement`
- **Owner**: MathieuBengle
- **URL**: https://github.com/MathieuBengle/lumanitech-erp-db-procurement

### Database
- **Name**: `lumanitech_erp_procurement`
- **Module**: Procurement
- **API**: [lumanitech-erp-api-procurement](https://github.com/MathieuBengle/lumanitech-erp-api-procurement)

### Directory Structure
```
lumanitech-erp-db-procurement/
├── migrations/        # V###_description.sql files
├── schema/
│   ├── tables/       # Current table definitions
│   ├── views/
│   ├── procedures/
│   ├── functions/
│   ├── triggers/
│   └── indexes/
├── seeds/
│   └── dev/          # Development seed data
├── scripts/
│   ├── deploy.sh
│   ├── validate.sh
│   └── apply-migrations.sh
└── docs/
    ├── migration-strategy.md
    └── schema.md
```

## Getting Help

### Resources
- [Migration Strategy](./docs/migration-strategy.md)
- [Schema Documentation](./docs/schema.md)
- [Scripts Guide](./scripts/README.md)
- [Seeds Guide](./seeds/README.md)

### Support
- **Issues**: Create an issue for bugs or questions
- **Discussions**: Use GitHub Discussions for general questions
- **Reviews**: Tag @procurement-team for PR reviews

## Code of Conduct

- Be respectful and professional
- Provide constructive feedback
- Focus on the code, not the person
- Help others learn and grow

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to Lumanitech ERP Procurement Database! 🎉
