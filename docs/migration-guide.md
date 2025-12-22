# Migration Guide - Procurement Database

## 📋 Vue d'ensemble

Ce guide détaillé explique comment gérer les migrations de la base de données Procurement selon la stratégie **forward-only**.

## 🎯 Philosophie forward-only

### Principe de base

Une stratégie **forward-only** signifie que les migrations sont **unidirectionnelles** :
- On ne peut qu'avancer (forward), jamais revenir en arrière (rollback)
- Chaque migration modifie la base vers un nouvel état
- Les erreurs sont corrigées par de nouvelles migrations, pas par annulation

### Pourquoi forward-only ?

**Avantages :**
- ✅ Simplicité : Pas besoin d'écrire et maintenir du code de rollback
- ✅ Sécurité : Évite les pertes de données accidentelles
- ✅ Traçabilité : Historique complet des changements
- ✅ Production-ready : Reflète la réalité (on ne rollback pas en prod)
- ✅ Cohérence : Un seul chemin d'évolution du schéma

**Inconvénients :**
- ❌ Correction d'erreur nécessite une nouvelle migration
- ❌ Tests plus importants avant application

## 📝 Cycle de vie d'une migration

```
1. Planification
   └─> Analyse du besoin
   └─> Design de la modification

2. Création
   └─> Génération du fichier VXXX_description.sql
   └─> Écriture du SQL
   └─> Documentation dans le header

3. Test local
   └─> Application sur base de dev
   └─> Vérification du résultat
   └─> Tests de l'application

4. Review
   └─> PR sur GitHub
   └─> Review par les pairs
   └─> Validation CI/CD

5. Merge
   └─> Merge dans main
   └─> Migration devient immutable

6. Déploiement
   └─> Application en staging
   └─> Validation
   └─> Application en production
```

## 🔨 Créer une migration

### Étape 1 : Déterminer le numéro de version

```bash
cd migrations
ls -1 V*.sql | tail -1
# Output: V005_create_reporting_views.sql
# → Prochain numéro : V006
```

### Étape 2 : Créer le fichier

```bash
touch V006_add_contracts_table.sql
```

### Étape 3 : Utiliser le template

```sql
-- Migration: V006_add_contracts_table
-- Created: 2024-12-21
-- Author: Jean Dupont
-- Description: Ajout de la table contracts pour gérer les contrats-cadres
--              avec les fournisseurs. Cette table stocke les informations
--              sur les accords à long terme incluant les dates de validité
--              et les conditions spécifiques.

START TRANSACTION;

-- Création de la table contracts
CREATE TABLE IF NOT EXISTS contracts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    contract_number VARCHAR(50) UNIQUE NOT NULL,
    supplier_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status ENUM('draft', 'active', 'expired', 'terminated') DEFAULT 'draft',
    total_value DECIMAL(15,2),
    currency VARCHAR(3) DEFAULT 'EUR',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED,
    updated_by BIGINT UNSIGNED,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT,
    INDEX idx_contract_number (contract_number),
    INDEX idx_supplier (supplier_id),
    INDEX idx_status (status),
    INDEX idx_dates (start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Contrats-cadres avec les fournisseurs';

-- Enregistrer la migration
INSERT INTO schema_migrations (version, description) 
VALUES ('V006', 'add_contracts_table')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;

COMMIT;
```

### Étape 4 : Tester localement

```bash
# Sauvegarder d'abord
mysqldump -u root -p procurement > backup_before_V006.sql

# Appliquer la migration
mysql -u root -p procurement < V006_add_contracts_table.sql

# Vérifier
mysql -u root -p procurement -e "DESCRIBE contracts;"
mysql -u root -p procurement -e "SELECT * FROM schema_migrations WHERE version='V006';"
```

### Étape 5 : Valider

```bash
../scripts/validate-migrations.sh
../scripts/check-syntax.sh
```

### Étape 6 : Créer une PR

```bash
git checkout -b feat/add-migration-V006-contracts
git add V006_add_contracts_table.sql
git commit -m "feat: add contracts table migration"
git push origin feat/add-migration-V006-contracts
```

## 📚 Cas d'usage courants

### Ajouter une nouvelle table

```sql
-- Migration: VXXX_add_table_name
CREATE TABLE IF NOT EXISTS table_name (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    -- colonnes...
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Ajouter une colonne

```sql
-- Migration: VXXX_add_column_to_table
ALTER TABLE table_name 
ADD COLUMN IF NOT EXISTS new_column VARCHAR(100) 
AFTER existing_column;
```

### Ajouter un index

```sql
-- Migration: VXXX_add_index_on_table
CREATE INDEX IF NOT EXISTS idx_table_column ON table_name(column_name);

-- Index composite
CREATE INDEX IF NOT EXISTS idx_table_col1_col2 ON table_name(col1, col2);
```

### Modifier une colonne (avec précaution)

```sql
-- Migration: VXXX_modify_column_type
-- ATTENTION : Vérifier la compatibilité des données existantes

-- Exemple : Agrandir un VARCHAR
ALTER TABLE table_name 
MODIFY COLUMN column_name VARCHAR(200);  -- était VARCHAR(100)

-- Exemple : Rendre nullable
ALTER TABLE table_name 
MODIFY COLUMN column_name VARCHAR(100) NULL;
```

### Ajouter une clé étrangère

```sql
-- Migration: VXXX_add_foreign_key
ALTER TABLE child_table
ADD CONSTRAINT fk_child_parent 
FOREIGN KEY (parent_id) REFERENCES parent_table(id) 
ON DELETE RESTRICT;
```

### Renommer une colonne

```sql
-- Migration: VXXX_rename_column
ALTER TABLE table_name 
CHANGE COLUMN old_name new_name VARCHAR(100) NOT NULL;
```

### Données de référence

```sql
-- Migration: VXXX_add_reference_data
INSERT IGNORE INTO reference_table (code, label, sort_order) VALUES
('code1', 'Label 1', 1),
('code2', 'Label 2', 2),
('code3', 'Label 3', 3);
```

### Créer une vue

```sql
-- Migration: VXXX_create_view_name
CREATE OR REPLACE VIEW view_name AS
SELECT 
    t1.id,
    t1.name,
    t2.description
FROM table1 t1
LEFT JOIN table2 t2 ON t1.id = t2.table1_id;
```

### Créer une procédure stockée

```sql
-- Migration: VXXX_create_procedure_name
DELIMITER //

DROP PROCEDURE IF EXISTS procedure_name//

CREATE PROCEDURE procedure_name(
    IN param1 BIGINT,
    OUT param2 VARCHAR(255)
)
BEGIN
    -- Logique de la procédure
    SELECT name INTO param2 FROM table_name WHERE id = param1;
END//

DELIMITER ;
```

## ⚠️ Gestion des erreurs

### Scénario 1 : Migration échouée en dev

**Situation** : La migration échoue lors des tests locaux

**Solution** :
1. Analyser l'erreur
2. Modifier la migration (pas encore mergée)
3. Retester
4. Recommencer jusqu'à succès

```bash
# Restaurer la base
mysql -u root -p procurement < backup_before_VXXX.sql

# Corriger le fichier VXXX_*.sql

# Réessayer
mysql -u root -p procurement < VXXX_*.sql
```

### Scénario 2 : Erreur détectée après merge

**Situation** : Migration mergée dans main mais erreur détectée

**Solution** : Créer une migration corrective

```sql
-- Migration: VXXX+1_fix_previous_migration
-- Description: Correction de la migration VXXX qui avait un problème X

START TRANSACTION;

-- Correction du problème
-- Exemple : colonne manquante
ALTER TABLE table_name 
ADD COLUMN IF NOT EXISTS missing_column VARCHAR(100);

-- Ou : contrainte incorrecte
ALTER TABLE table_name 
DROP FOREIGN KEY fk_incorrect;

ALTER TABLE table_name
ADD CONSTRAINT fk_correct 
FOREIGN KEY (column_id) REFERENCES other_table(id);

INSERT INTO schema_migrations (version, description) 
VALUES ('VXXX+1', 'fix_previous_migration');

COMMIT;
```

### Scénario 3 : Besoin de rollback conceptuel

**Situation** : Besoin d'annuler un changement fait par une migration précédente

**Solution** : Migration "inverse"

```sql
-- Si V010 a ajouté une colonne :
-- Migration: V011_remove_unnecessary_column
ALTER TABLE table_name DROP COLUMN column_added_in_v010;

-- Si V010 a créé une table :
-- Migration: V011_drop_unnecessary_table
DROP TABLE IF EXISTS table_created_in_v010;
```

### Scénario 4 : Conflits de numérotation

**Situation** : Deux PRs créent le même numéro de migration

**Solution** :
1. La première PR mergée garde son numéro
2. La seconde PR doit renommer sa migration

```bash
# Dans la branche de la 2ème PR
git mv migrations/V010_feature_b.sql migrations/V011_feature_b.sql

# Modifier le header du fichier
# Migration: V011_feature_b  (au lieu de V010)

# Mettre à jour la table de suivi
# VALUES ('V011', 'feature_b')  (au lieu de V010)

git add migrations/V011_feature_b.sql
git commit -m "fix: renumber migration to V011 to avoid conflict"
```

## 🛡️ Bonnes pratiques

### 1. Tests exhaustifs

```bash
# Tests unitaires de la migration
mysql -u root -p test_db < VXXX_migration.sql

# Tests d'intégration
# - Vérifier que l'API fonctionne toujours
# - Vérifier les requêtes existantes
# - Tester les nouvelles fonctionnalités
```

### 2. Idempotence

Toujours utiliser `IF NOT EXISTS` / `IF EXISTS` :

```sql
-- ✅ Bon
CREATE TABLE IF NOT EXISTS my_table (...);
ALTER TABLE my_table ADD COLUMN IF NOT EXISTS my_column VARCHAR(100);
CREATE INDEX IF NOT EXISTS idx_my_column ON my_table(my_column);

-- ❌ Risqué
CREATE TABLE my_table (...);
ALTER TABLE my_table ADD COLUMN my_column VARCHAR(100);
```

### 3. Sauvegardes

```bash
# Avant chaque migration importante
mysqldump -u root -p procurement > backup_$(date +%Y%m%d_%H%M%S).sql
```

### 4. Migrations par étapes

Pour les changements complexes, créer plusieurs migrations :

```sql
-- V010_prepare_column_rename.sql
ALTER TABLE users ADD COLUMN email_address VARCHAR(255);
UPDATE users SET email_address = email;

-- V011_complete_column_rename.sql
ALTER TABLE users DROP COLUMN email;
```

### 5. Documentation

Documenter clairement :

```sql
-- Migration: VXXX_descriptive_name
-- Created: YYYY-MM-DD
-- Author: Nom
-- Description: Explication détaillée du POURQUOI et du COMMENT
--              Mentionner les impacts potentiels
--              Lister les dépendances
-- Breaking changes: OUI/NON - Détails si oui
-- Rollback strategy: Comment annuler conceptuellement si nécessaire
```

### 6. Performances

Pour les migrations sur grandes tables :

```sql
-- Désactiver les index pendant insertion massive
ALTER TABLE large_table DISABLE KEYS;

-- Insertion
INSERT INTO large_table (...) VALUES (...);

-- Réactiver
ALTER TABLE large_table ENABLE KEYS;

-- Ou utiliser ALGORITHM=INPLACE pour ALTER TABLE
ALTER TABLE large_table 
ADD COLUMN new_column INT,
ALGORITHM=INPLACE, LOCK=NONE;
```

## 📊 Suivi des migrations

### Table schema_migrations

```sql
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(50) PRIMARY KEY,
    description VARCHAR(255),
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_applied_at (applied_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Vérifier les migrations appliquées

```sql
-- Toutes les migrations
SELECT * FROM schema_migrations ORDER BY version;

-- Dernière migration
SELECT * FROM schema_migrations ORDER BY applied_at DESC LIMIT 1;

-- Migrations manquantes (comparé aux fichiers)
-- À implémenter dans script de validation
```

## 🚀 Déploiement

### Environnement de développement

```bash
# Application manuelle
mysql -u root -p procurement < migrations/VXXX_migration.sql

# Ou via script
./scripts/apply-migrations.sh --env dev
```

### Environnement de staging

```bash
# 1. Backup
mysqldump -u user -p staging_db > backup_staging_$(date +%Y%m%d).sql

# 2. Appliquer
./scripts/apply-migrations.sh --env staging

# 3. Valider
./scripts/verify-schema.sh --env staging
```

### Environnement de production

```bash
# 1. Planifier une fenêtre de maintenance
# 2. Notifier les utilisateurs
# 3. Backup complet
mysqldump -u user -p prod_db > backup_prod_$(date +%Y%m%d_%H%M%S).sql

# 4. Appliquer les migrations
./scripts/apply-migrations.sh --env production

# 5. Vérifier
./scripts/verify-schema.sh --env production

# 6. Monitorer l'application
# 7. Confirmer le succès
```

## 📞 Support

**Questions** : Créer une issue GitHub  
**Problèmes** : Contacter l'équipe DBA  
**Urgences production** : Oncall DBA

## 📚 Références

- [README principal](../README.md)
- [Guide des migrations](../migrations/README.md)
- [Design du schéma](schema-design.md)
- [Dictionnaire de données](data-dictionary.md)
