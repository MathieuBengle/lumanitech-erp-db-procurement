# Views

Ce dossier contient les définitions des vues SQL.

## Format

Un fichier par vue, nommé `view_name.sql`

## Exemple

```sql
-- View: active_suppliers_summary
-- Description: Vue résumée des fournisseurs actifs

CREATE OR REPLACE VIEW active_suppliers_summary AS
SELECT 
    id,
    name,
    code,
    email,
    city,
    country
FROM suppliers
WHERE status = 'active';
```
