# Lumanitech ERP - Procurement Database

Database schema and migrations for the Procurement module of the Lumanitech ERP system.

## 📋 Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Migration Strategy](#migration-strategy)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Development](#development)
- [Related Repositories](#related-repositories)

## 🎯 Overview

This repository contains **only** the database schema definitions, migrations, and reference data for the Procurement module. It does **not** contain application code.

### Functional Scope

The Procurement module manages:
- **Suppliers**: Vendor master data and contact information
- **Purchase Requests**: Internal requests for goods/services
- **Purchase Orders**: Orders sent to suppliers
- **Goods Receipts**: Receipt of ordered items
- **Vendor Invoices**: Invoices received from suppliers
- **Contracts & Agreements**: Long-term supplier agreements

### Technology

- **Database**: MySQL 8.0+
- **Character Set**: UTF-8 (utf8mb4)
- **Storage Engine**: InnoDB
- **Host**: WHC (Web Hosting Canada)

## 📁 Repository Structure

```
lumanitech-erp-db-procurement/
├── CONTRIBUTING.md              # Contribution guidelines
├── README.md                    # This file
├── migrations/                  # Versioned migration scripts
│   ├── TEMPLATE.sql            # Migration template
│   ├── README.md               # Migration guide
│   └── V###_*.sql             # Migration files (e.g., V001_init_schema.sql)
├── schema/                      # Current schema definition
│   ├── README.md               # Schema organization guide
│   ├── tables/                 # Table definitions
│   ├── views/                  # SQL views
│   ├── procedures/             # Stored procedures
│   ├── functions/              # SQL functions
│   ├── triggers/               # Database triggers
│   └── indexes/                # Standalone index definitions
├── seeds/                       # Seed data for development
│   ├── README.md               # Seed data guide
│   └── dev/                    # Development seed data
│       ├── countries.sql       # ISO country codes
│       ├── currencies.sql      # ISO currency codes
│       ├── order_statuses.sql  # Order status reference data
│       └── sample_suppliers.sql # Sample supplier data
├── scripts/                     # Automation and deployment scripts
│   ├── README.md               # Script documentation
│   ├── deploy.sh               # Main deployment script
│   ├── apply-migrations.sh     # Migration application script
│   ├── validate.sh             # Validation wrapper script
│   ├── validate-migrations.sh  # Migration validation
│   └── check-syntax.sh         # SQL syntax checker
└── docs/                        # Documentation
    ├── migration-strategy.md   # Migration strategy guide
    ├── schema.md               # Schema documentation
    ├── schema-design.md        # Design decisions (legacy)
    ├── data-dictionary.md      # Data dictionary (legacy)
    └── migration-guide.md      # Detailed migration guide (legacy)
```

## 🔄 Migration Strategy

### Forward-Only Migrations

This repository uses a **forward-only migration strategy**:

✅ **Allowed:**
- Migrations that add new structures (tables, columns, indexes)
- Migrations that modify data
- Migrations that create new constraints

❌ **Forbidden:**
- Rollback files (`*_down.sql`, `*_rollback.sql`)
- Deleting columns without a corrective migration
- Destructive modifications without a recovery plan

### Naming Convention

Migrations follow the format: `V###_description.sql`

Where:
- `V` = Version prefix (required)
- `###` = Three-digit sequential number (001, 002, 003, ...)
- `description` = Brief description in snake_case (English)

**Examples:**
```
V001_init_schema.sql
V002_add_suppliers_table.sql
V003_add_purchase_orders_table.sql
V004_add_audit_columns.sql
```

### Key Rules

1. **Sequential**: Migrations are applied in numerical order
2. **Immutable**: Once merged to `main`, a migration must NEVER be modified
3. **Corrective**: To fix an error, create a new migration
4. **Idempotent**: Use `IF NOT EXISTS` and `IF EXISTS` when appropriate
5. **Transactional**: Each migration should be wrapped in a transaction
6. **Self-Tracking**: Every migration inserts into `schema_migrations` table

### Migration Template

```sql
-- Migration: V###_description
-- Created: YYYY-MM-DD
-- Author: Your Name
-- Description: Detailed description of the migration

START TRANSACTION;

-- Your migration code here
CREATE TABLE IF NOT EXISTS example_table (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Record migration
INSERT INTO schema_migrations (version, description) 
VALUES ('V###', 'description')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;

COMMIT;
```

## 🚀 Getting Started

### Prerequisites

- MySQL 8.0+ client
- Git
- Local MySQL server (for development)

### Installation

1. **Clone the repository:**

```bash
git clone https://github.com/MathieuBengle/lumanitech-erp-db-procurement.git
cd lumanitech-erp-db-procurement
```

2. **Create the database:**

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS lumanitech_erp_procurement CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

3. **Set up credentials (recommended):**

```bash
mysql_config_editor set --login-path=local \
    --host=localhost \
    --user=admin \
    --password
```

4. **Deploy schema and migrations:**

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Deploy everything with seed data
./scripts/deploy.sh --login-path=local --with-seeds
```

### Verification

```bash
# Check applied migrations
mysql --login-path=local lumanitech_erp_procurement -e "SELECT * FROM schema_migrations ORDER BY version;"

# Check tables
mysql --login-path=local lumanitech_erp_procurement -e "SHOW TABLES;"

# Check suppliers table
mysql --login-path=local lumanitech_erp_procurement -e "DESCRIBE suppliers;"
```

## 📖 Usage

### Deploying to an Environment

**Development (with seeds):**
```bash
./scripts/deploy.sh --login-path=local --with-seeds
```

**Staging (without seeds):**
```bash
./scripts/deploy.sh \
    --host=staging-db.example.com \
    --database=lumanitech_erp_procurement \
    --user=deploy_user
```

**Production (no seeds!):**
```bash
./scripts/deploy.sh \
    --host=prod-db.example.com \
    --database=lumanitech_erp_procurement \
    --user=deploy_user
```

### Running Migrations Only

```bash
./scripts/apply-migrations.sh \
    --login-path=local \
    --database=lumanitech_erp_procurement
```

### Loading Seed Data

```bash
# All seed data from seeds/dev/
./scripts/deploy.sh --login-path=local --with-seeds

# Or manually
mysql --login-path=local lumanitech_erp_procurement < seeds/dev/countries.sql
mysql --login-path=local lumanitech_erp_procurement < seeds/dev/currencies.sql
mysql --login-path=local lumanitech_erp_procurement < seeds/dev/sample_suppliers.sql
```

### Validation

```bash
# Run all validation checks
./scripts/validate.sh

# Validate migrations only
./scripts/validate-migrations.sh

# Check SQL syntax
./scripts/check-syntax.sh
```

## 💻 Development

### Creating a New Migration

1. **Determine the next version number:**

```bash
cd migrations
ls -1 V*.sql | tail -1
# Output: V001_init_schema.sql
# Next number: V002
```

2. **Create the migration file:**

```bash
touch V002_add_purchase_orders.sql
```

3. **Edit using TEMPLATE.sql as a guide:**

```bash
# Copy template structure
cp TEMPLATE.sql V002_add_purchase_orders.sql
# Edit the file with your changes
```

4. **Test locally:**

```bash
# Backup first
mysqldump --login-path=local lumanitech_erp_procurement > backup.sql

# Apply migration
mysql --login-path=local lumanitech_erp_procurement < V002_add_purchase_orders.sql

# Verify
mysql --login-path=local lumanitech_erp_procurement -e "SELECT * FROM schema_migrations WHERE version='V002';"
```

5. **Validate:**

```bash
cd ..
./scripts/validate.sh
```

6. **Create a Pull Request:**

```bash
git checkout -b feat/migration-002-purchase-orders
git add migrations/V002_add_purchase_orders.sql
git commit -m "feat: add purchase orders table migration"
git push origin feat/migration-002-purchase-orders
```

### Contribution Guidelines

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines on:
- Development workflow
- Migration best practices
- Pull request process
- Code standards
- Testing requirements

## 🔗 Related Repositories

### API Repository

This database is owned and consumed by:
- **Repository**: [lumanitech-erp-api-procurement](https://github.com/MathieuBengle/lumanitech-erp-api-procurement)
- **Responsibility**: Procurement API implements business logic and exposes endpoints

### Important Notes

- This database is **NOT** accessed directly by UIs
- This database is **NOT** shared with other ERP modules
- All access goes through the Procurement API
- Cross-domain data access happens via API Gateway

## 📚 Documentation

- [Migration Strategy](./docs/migration-strategy.md) - Detailed migration approach
- [Schema Documentation](./docs/schema.md) - Database schema reference
- [Scripts Guide](./scripts/README.md) - Script usage and examples
- [Seeds Guide](./seeds/README.md) - Seed data management
- [Contributing Guide](./CONTRIBUTING.md) - How to contribute

## 🛡️ Ownership and Responsibility

### Database Owner

- **Team**: Procurement API Team
- **Responsibility**: Define business needs, propose schema changes, consume the database

### Workflow

```
┌─────────────────────────────────────┐
│   Procurement API                   │
│   - Defines business requirements   │
│   - Proposes schema changes         │
│   - Consumes database               │
└─────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   DB Repository (this repo)         │
│   - Stores SQL migrations          │
│   - Documents schema               │
│   - Validates consistency          │
└─────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   MySQL Database Server             │
│   - Executes migrations            │
│   - Hosts data                     │
└─────────────────────────────────────┘
```

## ✅ Validation and CI/CD

### Pre-Commit Validation

Before committing:
```bash
./scripts/validate.sh
```

### CI Pipeline

The CI pipeline automatically:
1. Validates migration naming and sequence
2. Checks SQL syntax
3. Verifies best practices
4. Dry-runs migrations on test database

### Local Testing

```bash
# Full deployment test
./scripts/deploy.sh --login-path=local --with-seeds

# Validation only
./scripts/validate.sh
```

## 📄 License

Proprietary - Lumanitech © 2024

---

**Note**: This repository contains only SQL. For application code, see the [Procurement API repository](https://github.com/MathieuBengle/lumanitech-erp-api-procurement).
