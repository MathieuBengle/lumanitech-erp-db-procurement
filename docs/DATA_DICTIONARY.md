# Data Dictionary

Comprehensive data dictionary for the Procurement database.

## schema_migrations

Tracks all applied database migrations.

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| version | VARCHAR(50) | NO | PRI | | Migration version (e.g., V001, V002) |
| description | VARCHAR(255) | NO | | | Brief description of the migration |
| applied_at | TIMESTAMP | NO | MUL | CURRENT_TIMESTAMP | When the migration was applied |

**Indexes:**
- PRIMARY KEY: version
- INDEX: idx_applied_at (applied_at)

## countries

ISO 3166-1 country codes for address management.

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| code | VARCHAR(3) | NO | PRI | | ISO 3166-1 alpha-3 code |
| name | VARCHAR(100) | NO | MUL | | Country name in English |
| name_fr | VARCHAR(100) | YES | | NULL | Country name in French |
| alpha2 | VARCHAR(2) | YES | UNI | NULL | ISO 3166-1 alpha-2 code |
| region | VARCHAR(50) | YES | MUL | NULL | Geographic region |
| subregion | VARCHAR(50) | YES | | NULL | Geographic subregion |

**Indexes:**
- PRIMARY KEY: code
- UNIQUE: alpha2
- INDEX: idx_name (name)
- INDEX: idx_region (region)

## currencies

ISO 4217 currency codes for multi-currency support.

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| code | VARCHAR(3) | NO | PRI | | ISO 4217 currency code |
| name | VARCHAR(50) | NO | MUL | | Currency name |
| symbol | VARCHAR(10) | YES | | NULL | Currency symbol |
| decimal_places | TINYINT | YES | | 2 | Number of decimal places |

**Indexes:**
- PRIMARY KEY: code
- INDEX: idx_name (name)

## order_statuses

Purchase order status codes for workflow management.

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| code | VARCHAR(50) | NO | PRI | | Status code |
| label | VARCHAR(100) | NO | | | Status label in English |
| label_fr | VARCHAR(100) | YES | | NULL | Status label in French |
| description | TEXT | YES | | NULL | Detailed description |
| sort_order | INT | YES | MUL | 0 | Display order |
| is_active | BOOLEAN | YES | | TRUE | Whether status is active |
| color | VARCHAR(20) | YES | | NULL | UI color code |

**Indexes:**
- PRIMARY KEY: code
- INDEX: idx_sort_order (sort_order)

## suppliers

Supplier master data for procurement operations.

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PRI | AUTO_INCREMENT | Unique identifier |
| code | VARCHAR(50) | NO | UNI | | Supplier code (e.g., SUP-001) |
| name | VARCHAR(255) | NO | MUL | | Supplier name |
| email | VARCHAR(255) | YES | | NULL | Contact email |
| phone | VARCHAR(50) | YES | | NULL | Contact phone |
| address | TEXT | YES | | NULL | Street address |
| city | VARCHAR(100) | YES | MUL | NULL | City |
| country | VARCHAR(3) | YES | MUL | NULL | Country code (FK to countries) |
| status | ENUM('active','inactive','blocked') | YES | MUL | active | Supplier status |
| created_at | TIMESTAMP | NO | | CURRENT_TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | NO | | CURRENT_TIMESTAMP | Last update timestamp |
| created_by | BIGINT UNSIGNED | YES | | NULL | User who created |
| updated_by | BIGINT UNSIGNED | YES | | NULL | User who last updated |

**Indexes:**
- PRIMARY KEY: id
- UNIQUE: code
- INDEX: idx_name (name)
- INDEX: idx_status (status)
- INDEX: idx_city_country (city, country)

**Foreign Keys:**
- country → countries(code) ON DELETE SET NULL

## Naming Conventions

### Tables
- Lowercase, plural, snake_case
- Examples: suppliers, purchase_orders, order_items

### Columns
- Lowercase, snake_case
- Examples: created_at, order_number, total_amount

### Procedures
- Prefix: `sp_`
- Example: `sp_update_supplier_status.sql`

### Triggers
- Prefix: `trg_`
- Example: `trg_suppliers_before_update.sql`

### Indexes
- Prefix: `idx_`
- Format: `idx_<table>_<column(s)>`
- Example: idx_suppliers_code

### Foreign Keys
- Prefix: `fk_`
- Format: `fk_<child>_<parent>`
- Example: fk_suppliers_countries
