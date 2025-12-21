# Procedures

Ce dossier contient les définitions des procédures stockées.

## Format

Un fichier par procédure, nommé `procedure_name.sql`

## Exemple

```sql
-- Procedure: update_supplier_status
-- Description: Met à jour le statut d'un fournisseur

DELIMITER //

DROP PROCEDURE IF EXISTS update_supplier_status//

CREATE PROCEDURE update_supplier_status(
    IN p_supplier_id BIGINT UNSIGNED,
    IN p_new_status VARCHAR(20)
)
BEGIN
    UPDATE suppliers 
    SET status = p_new_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_supplier_id;
END//

DELIMITER ;
```
