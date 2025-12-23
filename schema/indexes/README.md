# Indexes

This directory contains standalone index definitions for the Procurement database.

## Purpose

Indexes improve query performance by allowing the database to quickly locate data without scanning entire tables.

## Organization

- Each file should focus on a specific table or related set of indexes
- Use descriptive filenames: `table_name_indexes.sql`

## Naming Convention

- Index names should follow the pattern: `idx_tablename_column(s)`
- Composite indexes: `idx_tablename_col1_col2`
- Unique indexes: `idx_unique_tablename_column`

## Example

```sql
-- Indexes for suppliers table
CREATE INDEX IF NOT EXISTS idx_suppliers_city_country 
ON suppliers(city, country);

CREATE INDEX IF NOT EXISTS idx_suppliers_status 
ON suppliers(status);
```

## Notes

- Most indexes are defined inline within table definitions in `schema/tables/`
- This directory is for indexes that need to be:
  - Created separately (e.g., after bulk data loads)
  - Modified independently of table structure
  - Added for performance tuning

## Current Status

Currently, all indexes are defined inline with their table definitions in `schema/tables/`. This directory is reserved for future standalone index definitions if needed.
