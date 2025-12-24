# Seeds

This directory contains seed data for the Procurement database.

## 📁 Organization

```
seeds/
├── README.md       # This file
└── dev/            # Development and test seed data
```

## 🎯 Purpose

Seed data provides initial or reference data needed for:
- **Development**: Local development environment setup
- **Testing**: Automated and manual testing scenarios  
- **Demos**: Demonstration and training environments

## ⚠️ Important Notes

### Production Use

**DO NOT load seed data in production environments.**

Seed data is intended only for:
- ✅ Local development
- ✅ Test environments
- ✅ Staging (with caution)
- ❌ **NEVER production**

### Data Types

This directory contains two types of data:

1. **Reference Data**: Essential data required for the application to function
   - Countries (ISO codes)
   - Currencies (ISO codes)
   - Order statuses
   - System configuration values

2. **Sample Data**: Fictitious data for development and testing
   - Sample suppliers
   - Test purchase orders
   - Demo user data

## 🚀 Usage

### Loading All Seeds

Use the deployment script with the `--with-seeds` flag:

```bash
./scripts/deploy.sh --with-seeds
```

This will:
1. Create/verify the database schema
2. Apply all migrations
3. Load all seed files from `seeds/dev/`

### Loading Seeds Manually

To load seeds manually:

```bash
# Load all dev seeds
for file in seeds/dev/*.sql; do
    echo "Loading $file..."
    mysql -u admin -p lumanitech_erp_procurement < "$file"
done

# Or load specific seed files
mysql -u admin -p lumanitech_erp_procurement < seeds/dev/countries.sql
mysql -u admin -p lumanitech_erp_procurement < seeds/dev/currencies.sql
```

### Using Login Path

If you've configured a login path with `mysql_config_editor`:

```bash
mysql --login-path=local lumanitech_erp_procurement < seeds/dev/countries.sql
```

## 📝 Seed Files

Current seed files in `dev/`:

- **countries.sql**: ISO 3166-1 country codes (reference data)
- **currencies.sql**: ISO 4217 currency codes (reference data)
- **order_statuses.sql**: Purchase order status codes (reference data)
- **sample_suppliers.sql**: Fictitious supplier data (sample data)

## ✅ Best Practices

### Idempotency

All seed files should be idempotent (safe to run multiple times):

```sql
-- ✅ Good - can be run multiple times
INSERT IGNORE INTO countries (code, name) VALUES ('USA', 'United States');

INSERT INTO countries (code, name) 
VALUES ('FRA', 'France')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- ❌ Bad - will fail on second run
INSERT INTO countries (code, name) VALUES ('USA', 'United States');
```

### Dependencies

Load seed files in the correct order to respect foreign key constraints:

```bash
# 1. Reference tables with no dependencies
mysql < seeds/dev/countries.sql
mysql < seeds/dev/currencies.sql

# 2. Tables that reference others
mysql < seeds/dev/sample_suppliers.sql  # references countries
```

### Data Quality

- Use realistic but fictitious data for samples
- Use `.example.com` domains for email addresses
- Avoid real phone numbers or addresses
- Never include sensitive or personal data
- Follow the same data validation rules as production

## 🔧 Maintenance

### Adding New Seed Files

1. Create the file in `seeds/dev/`:
   ```bash
   touch seeds/dev/new_seed.sql
   ```

2. Follow the standard format:
   ```sql
   -- Seed: new_seed
   -- Type: reference|sample
   -- Description: What this seed provides
   -- Dependencies: List of required tables/seeds
   
   START TRANSACTION;
   
   INSERT IGNORE INTO table_name (columns) VALUES
   (values);
   
   COMMIT;
   ```

3. Test locally:
   ```bash
   mysql -u admin -p lumanitech_erp_procurement < seeds/dev/new_seed.sql
   ```

4. Commit and push:
   ```bash
   git add seeds/dev/new_seed.sql
   git commit -m "chore: add new seed data"
   ```

### Updating Existing Seeds

Reference data may need updates when:
- New ISO codes are published
- System status values change
- Configuration defaults are updated

Sample data should be updated to:
- Test new features
- Cover edge cases
- Improve developer experience

## 🔒 Security

- **Never commit secrets** (passwords, API keys, tokens)
- **Never commit PII** (real names, emails, addresses)
- **Use fake data generators** for realistic sample data
- **Review seed files** before committing to ensure no sensitive data

## 📞 Support

- **Questions**: Create an issue in this repository
- **New seed data**: Submit a PR with justification
- **Problems loading seeds**: Check the script logs and database permissions

## Related Documentation

- [Deployment Guide](../scripts/README.md)
- [Migration Strategy](../docs/migration-strategy.md)
- [Schema Documentation](../docs/schema.md)
