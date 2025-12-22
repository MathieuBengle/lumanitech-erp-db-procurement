# Migrations

Ce dossier contient les scripts de migration versionnés pour la base de données Procurement.

## 📋 Principe

Les migrations suivent une **stratégie forward-only** (unidirectionnelle). Chaque migration est appliquée séquentiellement et ne peut pas être annulée (pas de rollback).

## 📝 Convention de nommage

**Format** : `VXXX_description.sql`

- `V` : Préfixe obligatoire
- `XXX` : Numéro séquentiel à 3 chiffres (001, 002, 003, ...)
- `description` : Description courte en snake_case

**Exemples valides :**
```
V001_init_schema.sql
V002_add_suppliers_table.sql
V003_add_purchase_orders_table.sql
V004_add_email_to_suppliers.sql
V005_create_supplier_rating_view.sql
```

**Exemples invalides :**
```
001_init.sql                    # Manque le préfixe V
V1_init.sql                     # Numéro doit être à 3 chiffres
V001-init-schema.sql           # Utiliser underscore, pas tiret
V001_init_schema_rollback.sql  # Pas de rollback (forward-only)
```

## 🔨 Template de migration

```sql
-- Migration: VXXX_description
-- Created: YYYY-MM-DD
-- Author: Nom de l'auteur
-- Description: Description détaillée de ce que fait cette migration
--              Peut être sur plusieurs lignes

-- Start transaction (MySQL DDL auto-commits, mais utile pour documentation)
START TRANSACTION;

-- Exemple 1: Créer une table
CREATE TABLE IF NOT EXISTS suppliers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_code (code),
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Exemple 2: Ajouter une colonne
ALTER TABLE suppliers 
ADD COLUMN IF NOT EXISTS status ENUM('active', 'inactive', 'blocked') 
DEFAULT 'active' 
AFTER country;

-- Exemple 3: Créer un index
CREATE INDEX IF NOT EXISTS idx_status ON suppliers(status);

-- Commit
COMMIT;
```

## ✅ Règles importantes

### 1. Immutabilité
Une fois qu'une migration est mergée dans `main`, elle ne doit **JAMAIS** être modifiée.

❌ **Mauvais** : Modifier V001_init_schema.sql après merge
✅ **Bon** : Créer V006_fix_suppliers_schema.sql

### 2. Séquentialité
Les migrations sont appliquées dans l'ordre numérique strict.

- Toujours utiliser le prochain numéro disponible
- Pas de sauts dans la numérotation
- Pas de doublons

### 3. Idempotence
Utiliser `IF NOT EXISTS` et `IF EXISTS` pour permettre de rejouer les migrations.

```sql
-- ✅ Bon
CREATE TABLE IF NOT EXISTS my_table (...);
ALTER TABLE my_table ADD COLUMN IF NOT EXISTS my_column VARCHAR(100);

-- ❌ Risqué
CREATE TABLE my_table (...);  -- Échoue si la table existe déjà
```

### 4. Forward-Only
Pas de fichiers de rollback. Pour annuler un changement, créer une nouvelle migration.

```sql
-- Si V003 ajoute une colonne qu'on veut retirer
-- ❌ Mauvais : Créer V003_rollback.sql
-- ✅ Bon : Créer V004_remove_unwanted_column.sql
```

### 5. Transactions
Bien que MySQL auto-commit les DDL, documenter les transactions pour clarté.

```sql
START TRANSACTION;
-- DDL statements
COMMIT;
```

## 🚀 Workflow

### Créer une nouvelle migration

```bash
# 1. Vérifier le dernier numéro
cd migrations
ls -1 V*.sql | tail -1
# Output: V005_create_reporting_views.sql

# 2. Créer la nouvelle migration
touch V006_add_contracts_table.sql

# 3. Éditer avec votre SQL
nano V006_add_contracts_table.sql

# 4. Tester localement
mysql -u root -p procurement < V006_add_contracts_table.sql

# 5. Valider
../scripts/validate-migrations.sh
```

### Appliquer les migrations

```bash
# Toutes les migrations
../scripts/apply-migrations.sh

# Ou manuellement
for file in V*.sql; do
    echo "Applying $file..."
    mysql -u root -p procurement < "$file"
done
```

## 📊 Suivi des migrations

Pour suivre quelles migrations ont été appliquées, créer une table de suivi :

```sql
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(50) PRIMARY KEY,
    description VARCHAR(255),
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

Puis dans chaque migration :

```sql
-- À la fin de la migration
INSERT INTO schema_migrations (version, description) 
VALUES ('V006', 'add_contracts_table')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

## 🛡️ Bonnes pratiques

### Performance
- Créer les indexes après insertion de données volumineuses
- Utiliser `ALGORITHM=INPLACE` pour les ALTER TABLE quand possible
- Éviter les modifications de schéma en heures pleines

### Sécurité
- Pas de credentials hardcodés
- Pas de données sensibles en clair
- Utiliser des paramètres pour les données utilisateur

### Qualité
- Commentaires clairs et détaillés
- Tests locaux avant commit
- Review par un pair obligatoire

### Documentation
- Mettre à jour `/schema/` si nécessaire
- Mettre à jour le dictionnaire de données
- Documenter les breaking changes

## 📚 Exemples de migrations courantes

### Ajout d'une table

```sql
-- Migration: V007_add_purchase_orders
-- Created: 2024-12-21
-- Author: API Team
-- Description: Création de la table des bons de commande

START TRANSACTION;

CREATE TABLE IF NOT EXISTS purchase_orders (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    supplier_id BIGINT UNSIGNED NOT NULL,
    status ENUM('draft', 'submitted', 'approved', 'rejected', 'cancelled') DEFAULT 'draft',
    total_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'EUR',
    order_date DATE NOT NULL,
    expected_delivery_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED,
    updated_by BIGINT UNSIGNED,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT,
    INDEX idx_order_number (order_number),
    INDEX idx_supplier (supplier_id),
    INDEX idx_status (status),
    INDEX idx_order_date (order_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations (version, description) 
VALUES ('V007', 'add_purchase_orders');

COMMIT;
```

### Modification de structure

```sql
-- Migration: V008_add_audit_columns
-- Created: 2024-12-21
-- Author: API Team
-- Description: Ajout de colonnes d'audit sur toutes les tables

START TRANSACTION;

-- Suppliers
ALTER TABLE suppliers 
ADD COLUMN IF NOT EXISTS created_by BIGINT UNSIGNED AFTER updated_at,
ADD COLUMN IF NOT EXISTS updated_by BIGINT UNSIGNED AFTER created_by;

-- Purchase Orders (already has them)

INSERT INTO schema_migrations (version, description) 
VALUES ('V008', 'add_audit_columns');

COMMIT;
```

### Création d'index

```sql
-- Migration: V009_add_performance_indexes
-- Created: 2024-12-21
-- Author: DBA Team
-- Description: Ajout d'index pour améliorer les performances des requêtes

START TRANSACTION;

CREATE INDEX IF NOT EXISTS idx_suppliers_city_country 
ON suppliers(city, country);

CREATE INDEX IF NOT EXISTS idx_po_supplier_status 
ON purchase_orders(supplier_id, status);

INSERT INTO schema_migrations (version, description) 
VALUES ('V009', 'add_performance_indexes');

COMMIT;
```

### Données de référence

```sql
-- Migration: V010_add_default_statuses
-- Created: 2024-12-21
-- Author: API Team
-- Description: Insertion des statuses de référence

START TRANSACTION;

CREATE TABLE IF NOT EXISTS order_statuses (
    code VARCHAR(50) PRIMARY KEY,
    label VARCHAR(100) NOT NULL,
    description TEXT,
    sort_order INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO order_statuses (code, label, description, sort_order) VALUES
('draft', 'Brouillon', 'Commande en cours de création', 1),
('submitted', 'Soumise', 'Commande soumise pour approbation', 2),
('approved', 'Approuvée', 'Commande approuvée', 3),
('rejected', 'Rejetée', 'Commande rejetée', 4),
('cancelled', 'Annulée', 'Commande annulée', 5);

INSERT INTO schema_migrations (version, description) 
VALUES ('V010', 'add_default_statuses');

COMMIT;
```

## ⚠️ Gestion des erreurs

### Migration échouée

Si une migration échoue :

1. **Analyser l'erreur** : Comprendre pourquoi
2. **Ne PAS modifier la migration existante** si déjà mergée
3. **Créer une migration corrective** : VXXX_fix_previous_migration.sql
4. **Documenter** : Expliquer le problème et la solution

### Résoudre les conflits

En cas de conflits de numérotation entre branches :

1. **Renommer** votre migration avec le prochain numéro disponible
2. **Mettre à jour** toutes les références
3. **Tester** à nouveau

## 📞 Support

- **Questions** : Créer une issue dans le repository
- **Problèmes** : Contacter l'équipe DBA
- **Reviews** : Demander à l'équipe API Backend
