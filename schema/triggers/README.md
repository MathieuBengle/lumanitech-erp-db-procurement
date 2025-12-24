# Triggers

Ce dossier contient les définitions des triggers.

## Format

Un fichier par trigger, nommé `trg_<name>.sql`

## Exemple

```sql
-- Trigger: suppliers_before_update
-- Description: Valide les données avant mise à jour

DELIMITER //

DROP TRIGGER IF EXISTS suppliers_before_update//

CREATE TRIGGER suppliers_before_update
BEFORE UPDATE ON suppliers
FOR EACH ROW
BEGIN
    -- Valider l'email
    IF NEW.email IS NOT NULL AND NEW.email NOT LIKE '%@%' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid email format';
    END IF;
    
    -- Mettre à jour updated_at
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//

DELIMITER ;
```
