# Functions

Ce dossier contient les définitions des fonctions SQL.

## Format

Un fichier par fonction, nommé `function_name.sql`

## Exemple

```sql
-- Function: get_supplier_order_count
-- Description: Retourne le nombre de commandes pour un fournisseur

DELIMITER //

DROP FUNCTION IF EXISTS get_supplier_order_count//

CREATE FUNCTION get_supplier_order_count(p_supplier_id BIGINT UNSIGNED)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE order_count INT;
    
    SELECT COUNT(*) INTO order_count
    FROM purchase_orders
    WHERE supplier_id = p_supplier_id;
    
    RETURN order_count;
END//

DELIMITER ;
```
