# Scripts

Automation and deployment scripts for the Procurement database.

## 📋 Available Scripts

### deploy.sh

Main deployment script that orchestrates database creation, schema deployment, migrations, and optional seed data loading.

**Usage:**

```bash
./scripts/deploy.sh [OPTIONS]

Options:
  -h, --host HOST           MySQL host (default: localhost)
  -P, --port PORT           MySQL port (default: 3306)
  -d, --database NAME       Target database (default: lumanitech_erp_procurement)
  -u, --user USER           MySQL user (default: admin)
  --login-path=NAME         mysql_config_editor login path (default: local)
  --with-seeds             Load seeds from seeds/dev/
  --help                   Show help message
```

**Examples:**

```bash
# Deploy with login path (recommended)
./scripts/deploy.sh --login-path=local

# Deploy with seeds
./scripts/deploy.sh --login-path=local --with-seeds

# Deploy to a specific database
./scripts/deploy.sh --database=procurement_test --with-seeds

# Deploy with interactive password
./scripts/deploy.sh --user=root
```

**What it does:**

1. Creates the database if it doesn't exist
2. Deploys schema objects in order:
   - Tables
   - Views
   - Procedures
   - Functions
   - Triggers
   - Indexes
3. Applies all migrations from `migrations/`
4. Optionally loads seed data from `seeds/dev/`

### apply-migrations.sh

Applies database migrations in sequential order.

**Usage:**

```bash
./scripts/apply-migrations.sh [OPTIONS]

Options:
  --host HOST              MySQL host
  --port PORT              MySQL port
  --database NAME          Target database
  --user USER              MySQL user
  --login-path=NAME        mysql_config_editor login path
```

**Examples:**

```bash
# Apply migrations using login path
./scripts/apply-migrations.sh --login-path=local --database=lumanitech_erp_procurement

# Apply migrations with specific credentials
./scripts/apply-migrations.sh --host=localhost --user=admin --database=lumanitech_erp_procurement
```

### validate.sh

Runs all validation checks on the repository.

**Usage:**

```bash
./scripts/validate.sh
```

**What it validates:**

- Migration file naming conventions
- Migration sequence and numbering
- SQL syntax
- Dangerous SQL patterns
- Best practices compliance

**When to use:**

- Before committing changes
- In CI/CD pipelines
- After adding new migrations
- During code reviews

### validate-migrations.sh

Validates migration files for naming conventions, sequence, and structure.

**Usage:**

```bash
./scripts/validate-migrations.sh
```

**Checks:**

- ✅ Naming follows `V###_description.sql` pattern
- ✅ Sequential numbering (V001, V002, V003, ...)
- ✅ No duplicate version numbers
- ✅ No forbidden rollback files
- ✅ Presence of migration headers
- ✅ Use of transactions
- ✅ Idempotence patterns

### check-syntax.sh

Validates SQL syntax and detects problematic patterns.

**Usage:**

```bash
./scripts/check-syntax.sh
```

**Checks:**

- ✅ UTF-8 encoding
- ✅ Balanced parentheses and quotes
- ✅ IF NOT EXISTS usage
- ✅ ENGINE=InnoDB specification
- ✅ CHARSET=utf8mb4 specification
- ✅ Dangerous commands (TRUNCATE, DROP DATABASE)
- ✅ Naming conventions
- ✅ Best practices (timestamps, comments)

## 🔐 Authentication

### Using mysql_config_editor (Recommended)

Store credentials securely:

```bash
mysql_config_editor set --login-path=local \
    --host=localhost \
    --user=admin \
    --password
```

Then use the login path in scripts:

```bash
./scripts/deploy.sh --login-path=local
```

### Interactive Password

If you don't use a login path, you'll be prompted for a password:

```bash
./scripts/deploy.sh --user=admin
# Password: [enter password when prompted]
```

## 📖 Common Workflows

### Local Development Setup

```bash
# 1. Create login path
mysql_config_editor set --login-path=local \
    --host=localhost \
    --user=admin \
    --password

# 2. Deploy everything with seeds
./scripts/deploy.sh --login-path=local --with-seeds

# 3. Verify
mysql --login-path=local lumanitech_erp_procurement -e "SELECT * FROM schema_migrations;"
```

### Adding a New Migration

```bash
# 1. Create migration file
cd migrations
touch V002_add_purchase_orders.sql

# 2. Edit migration (follow TEMPLATE.sql)

# 3. Validate
cd ..
./scripts/validate.sh

# 4. Test locally
./scripts/apply-migrations.sh --login-path=local --database=lumanitech_erp_procurement

# 5. Commit
git add migrations/V002_add_purchase_orders.sql
git commit -m "feat: add purchase orders table migration"
```

### Testing Database Changes

```bash
# 1. Backup current state
mysqldump --login-path=local lumanitech_erp_procurement > backup.sql

# 2. Deploy changes
./scripts/deploy.sh --login-path=local --with-seeds

# 3. Test your changes
# ... run tests ...

# 4. Restore if needed
mysql --login-path=local lumanitech_erp_procurement < backup.sql
```

### CI/CD Validation

```bash
# Run all validation checks (used in CI)
./scripts/validate.sh

# Exit code 0 = all checks passed
# Exit code 1 = validation failed
```

## 🚀 Deployment Environments

### Development

```bash
./scripts/deploy.sh --login-path=local --with-seeds
```

### Staging

```bash
# Without seeds for staging
./scripts/deploy.sh \
    --host=staging-db.example.com \
    --database=lumanitech_erp_procurement \
    --user=deploy_user
```

### Production

```bash
# Production deployment (no seeds!)
./scripts/deploy.sh \
    --host=prod-db.example.com \
    --database=lumanitech_erp_procurement \
    --user=deploy_user

# NEVER use --with-seeds in production!
```

## ⚠️ Important Notes

### Seeds in Production

**NEVER load seed data in production:**

- ❌ Never use `--with-seeds` in production
- ✅ Seeds are for development and testing only
- ✅ Production data comes from migrations and application logic

### Migration Safety

- Migrations are **forward-only** (no rollback)
- Always test migrations locally first
- Backup before applying to production
- Migrations are **immutable** once merged

### Permissions

Scripts require appropriate MySQL permissions:

- `CREATE DATABASE` for database creation
- `CREATE TABLE`, `ALTER TABLE` for schema changes
- `INSERT`, `UPDATE` for seed data
- `SELECT` for validation queries

## 🔧 Troubleshooting

### "Login path not found"

```bash
# Create the login path
mysql_config_editor set --login-path=local --host=localhost --user=admin --password
```

### "Access denied"

Check your MySQL user permissions:

```sql
GRANT ALL PRIVILEGES ON lumanitech_erp_procurement.* TO 'admin'@'localhost';
FLUSH PRIVILEGES;
```

### "Migration already applied"

This is normal if the migration was previously run. The scripts are idempotent.

### Script permission denied

```bash
# Make scripts executable
chmod +x scripts/*.sh
```

## 📞 Support

- **Issues**: Create an issue in this repository
- **Questions**: Check existing documentation first
- **Bugs**: Report with script output and error messages

## Related Documentation

- [Migration Strategy](../docs/migration-strategy.md)
- [Schema Documentation](../docs/schema.md)
- [Seeds Guide](../seeds/README.md)
- [Main README](../README.md)
