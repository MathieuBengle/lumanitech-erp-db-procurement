# Quick Start Guide

Quick setup guide for the Procurement database.

## Prerequisites

- MySQL 8.0+
- Git
- mysql_config_editor (optional but recommended)

## Secure Authentication Setup

### Using mysql_config_editor (Recommended)

```bash
mysql_config_editor set --login-path=local \
    --host=localhost \
    --user=admin \
    --password
```

**WSL2 local note:**
Use a login-path configured with user 'admin'.
Example:
```bash
mysql_config_editor set --login-path=local --host=localhost --user=admin --password
```

### Manual Setup

```bash
# Clone repository
git clone https://github.com/MathieuBengle/lumanitech-erp-db-procurement.git
cd lumanitech-erp-db-procurement

# Deploy database with seeds
./scripts/deploy.sh --login-path=local --with-seeds
```

## Verification

```bash
# Check applied migrations
mysql --login-path=local lumanitech_erp_procurement -e "SELECT * FROM schema_migrations;"

# List tables
mysql --login-path=local lumanitech_erp_procurement -e "SHOW TABLES;"
```

## Next Steps

- See [README.md](../README.md) for full documentation
- See [migration-strategy.md](./migration-strategy.md) for migration workflow
- See [schema.md](./schema.md) for schema reference
