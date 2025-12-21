# Schema

Ce dossier contient la définition du schéma actuel de la base de données Procurement.

## 📋 Vue d'ensemble

Le schéma est organisé par type d'objet de base de données :

```
schema/
├── tables/       # Définitions complètes des tables
├── views/        # Vues SQL
├── procedures/   # Procédures stockées
├── functions/    # Fonctions SQL
└── triggers/     # Triggers
```

## 🎯 Objectif

Ce dossier sert de **documentation de référence** du schéma actuel. Il ne remplace **pas** les migrations, mais fournit une vue consolidée de l'état actuel de la base de données.

## 📝 Utilisation

### Pour développeurs

Consultez ces fichiers pour :
- Comprendre la structure des tables
- Voir les relations entre tables
- Identifier les colonnes et leurs types
- Comprendre les contraintes et index

### Pour la documentation

Ces fichiers sont la source de vérité pour :
- Générer le dictionnaire de données
- Créer des diagrammes ERD
- Documenter l'API

## 🔄 Synchronisation

**Important** : Ces fichiers doivent être mis à jour après chaque migration qui modifie le schéma.

### Processus recommandé

1. **Appliquer la migration** sur votre base locale
2. **Extraire le schéma** avec `mysqldump` ou scripts
3. **Mettre à jour** les fichiers dans ce dossier
4. **Committer** avec la migration

### Extraction automatique

```bash
# Extraire toutes les tables
mysqldump -u root -p --no-data --skip-triggers procurement > schema_dump.sql

# Extraire une table spécifique
mysqldump -u root -p --no-data procurement suppliers > schema/tables/suppliers.sql

# Extraire les vues
mysqldump -u root -p --no-data --no-create-info --no-create-db procurement > schema/views/all_views.sql

# Extraire les procédures et fonctions
mysqldump -u root -p --routines --no-create-info --no-data --no-create-db procurement > schema/procedures_functions.sql

# Extraire les triggers
mysqldump -u root -p --triggers --no-create-info --no-data --no-create-db procurement > schema/triggers/all_triggers.sql
```

## 📂 Organisation des fichiers

### Tables (`tables/`)

Un fichier par table, nommé `table_name.sql`

**Exemple** : `tables/suppliers.sql`
```sql
-- Table: suppliers
-- Description: Gestion des fournisseurs
-- Owner: Procurement API

CREATE TABLE IF NOT EXISTS suppliers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100),
    status ENUM('active', 'inactive', 'blocked') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED,
    updated_by BIGINT UNSIGNED,
    INDEX idx_code (code),
    INDEX idx_name (name),
    INDEX idx_status (status),
    INDEX idx_city_country (city, country)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Table des fournisseurs';
```

### Vues (`views/`)

Un fichier par vue, nommé `view_name.sql`

**Exemple** : `views/active_suppliers_summary.sql`
```sql
-- View: active_suppliers_summary
-- Description: Vue résumée des fournisseurs actifs
-- Dependencies: suppliers

CREATE OR REPLACE VIEW active_suppliers_summary AS
SELECT 
    id,
    name,
    code,
    email,
    city,
    country,
    created_at
FROM 
    suppliers
WHERE 
    status = 'active'
ORDER BY 
    name;
```

### Procédures (`procedures/`)

Un fichier par procédure, nommé `procedure_name.sql`

**Exemple** : `procedures/update_supplier_status.sql`
```sql
-- Procedure: update_supplier_status
-- Description: Met à jour le statut d'un fournisseur avec log
-- Parameters:
--   IN p_supplier_id: ID du fournisseur
--   IN p_new_status: Nouveau statut
--   IN p_user_id: ID de l'utilisateur effectuant le changement

DELIMITER //

CREATE PROCEDURE update_supplier_status(
    IN p_supplier_id BIGINT UNSIGNED,
    IN p_new_status VARCHAR(20),
    IN p_user_id BIGINT UNSIGNED
)
BEGIN
    UPDATE suppliers 
    SET 
        status = p_new_status,
        updated_by = p_user_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE 
        id = p_supplier_id;
END//

DELIMITER ;
```

### Fonctions (`functions/`)

Un fichier par fonction, nommé `function_name.sql`

**Exemple** : `functions/get_supplier_order_count.sql`
```sql
-- Function: get_supplier_order_count
-- Description: Retourne le nombre de commandes pour un fournisseur
-- Parameters:
--   p_supplier_id: ID du fournisseur
-- Returns: INT - Nombre de commandes

DELIMITER //

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

### Triggers (`triggers/`)

Un fichier par trigger, nommé `trigger_name.sql`

**Exemple** : `triggers/suppliers_before_update.sql`
```sql
-- Trigger: suppliers_before_update
-- Description: Valide les données avant mise à jour d'un fournisseur
-- Table: suppliers
-- Event: BEFORE UPDATE

DELIMITER //

CREATE TRIGGER suppliers_before_update
BEFORE UPDATE ON suppliers
FOR EACH ROW
BEGIN
    -- Valider l'email
    IF NEW.email IS NOT NULL AND NEW.email NOT LIKE '%@%' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid email format';
    END IF;
    
    -- Mettre à jour automatiquement updated_at
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//

DELIMITER ;
```

## 🔍 Scripts utiles

### Générer le schéma complet

```bash
# Script pour générer tout le schéma
cd /home/runner/work/lumanitech-erp-db-procurement/lumanitech-erp-db-procurement

# Créer un script de génération
cat > scripts/extract-schema.sh << 'EOF'
#!/bin/bash
# Script d'extraction du schéma

DB_NAME="procurement"
DB_USER="root"
SCHEMA_DIR="schema"

echo "Extracting schema for database: $DB_NAME"

# Tables
echo "Extracting tables..."
mkdir -p $SCHEMA_DIR/tables
for table in $(mysql -u $DB_USER -p -D $DB_NAME -e "SHOW TABLES" | grep -v "Tables_in"); do
    mysqldump -u $DB_USER -p --no-data $DB_NAME $table > $SCHEMA_DIR/tables/$table.sql
    echo "  - $table"
done

# Views
echo "Extracting views..."
mkdir -p $SCHEMA_DIR/views
# À implémenter selon les vues existantes

# Procedures
echo "Extracting procedures..."
mkdir -p $SCHEMA_DIR/procedures
# À implémenter selon les procédures existantes

# Functions
echo "Extracting functions..."
mkdir -p $SCHEMA_DIR/functions
# À implémenter selon les fonctions existantes

# Triggers
echo "Extracting triggers..."
mkdir -p $SCHEMA_DIR/triggers
# À implémenter selon les triggers existants

echo "Schema extraction complete!"
EOF

chmod +x scripts/extract-schema.sh
```

### Comparer avec la base de données

```bash
# Vérifier si le schéma documenté correspond à la base
# À implémenter : script de comparaison
```

## 📊 Conventions

### Nommage

- **Tables** : `plural_snake_case` (ex: `suppliers`, `purchase_orders`)
- **Colonnes** : `snake_case` (ex: `supplier_id`, `created_at`)
- **Index** : `idx_table_columns` (ex: `idx_suppliers_code`)
- **Foreign Keys** : `fk_table_referenced_table` (ex: `fk_po_supplier`)
- **Vues** : `descriptive_name` (ex: `active_suppliers_summary`)
- **Procédures** : `verb_noun` (ex: `update_supplier_status`)
- **Fonctions** : `get_noun` ou `calculate_noun` (ex: `get_supplier_count`)

### Types de données

- **IDs** : `BIGINT UNSIGNED AUTO_INCREMENT`
- **Texte court** : `VARCHAR(n)` avec longueur appropriée
- **Texte long** : `TEXT`
- **Montants** : `DECIMAL(15,2)` pour la précision
- **Dates** : `DATE` pour les dates, `TIMESTAMP` pour date+heure
- **Booléens** : `TINYINT(1)` ou `BOOLEAN`
- **Énumérations** : `ENUM()` pour les valeurs fixes

### Colonnes standard

Toutes les tables principales devraient avoir :

```sql
id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
created_by BIGINT UNSIGNED,
updated_by BIGINT UNSIGNED
```

### Commentaires

```sql
-- Commentaires SQL standards
# Commentaires MySQL
/* Commentaires multi-lignes */

-- Préférer le format standard SQL (-- )
```

## 🔗 Relations

### Diagramme ERD

Le diagramme Entity-Relationship est maintenu dans `/docs/schema-design.md`

### Clés étrangères

Toujours définir explicitement les clés étrangères :

```sql
FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT
```

Options de suppression :
- `RESTRICT` : Empêche la suppression si référencé
- `CASCADE` : Supprime les enregistrements liés
- `SET NULL` : Met à NULL si référence supprimée

## 📚 Documentation

Pour plus d'informations :

- [Dictionnaire de données](/docs/data-dictionary.md)
- [Design du schéma](/docs/schema-design.md)
- [Guide de migration](/docs/migration-guide.md)

## 🛠️ Maintenance

### Mise à jour après migration

```bash
# 1. Appliquer la migration
mysql -u root -p procurement < migrations/V00X_description.sql

# 2. Extraire le schéma modifié
./scripts/extract-schema.sh

# 3. Vérifier les changements
git diff schema/

# 4. Commiter avec la migration
git add migrations/V00X_description.sql schema/
git commit -m "feat: add migration X and update schema"
```

### Vérification de cohérence

```bash
# Comparer le schéma documenté avec la base réelle
# À implémenter
```
