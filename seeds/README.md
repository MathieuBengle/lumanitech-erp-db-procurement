# Seeds

Ce dossier contient les données de référence et les données d'exemple pour la base de données Procurement.

## 📋 Organisation

```
seeds/
├── reference/    # Données de référence (production)
└── sample/       # Données d'exemple (dev/test uniquement)
```

## 🎯 Types de données

### Données de référence (`reference/`)

Données **essentielles** au fonctionnement de l'application, déployées en **production**.

**Exemples :**
- Pays et codes ISO
- Devises
- Statuts prédéfinis
- Catégories de produits
- Unités de mesure
- Codes de taxes

**Caractéristiques :**
- Rarement modifiées
- Identiques en dev, test et production
- Nécessaires pour l'intégrité des données
- Versionnées comme le code

### Données d'exemple (`sample/`)

Données de **test et développement**, **JAMAIS** déployées en production.

**Exemples :**
- Fournisseurs fictifs
- Commandes de test
- Utilisateurs de démo
- Données pour tests automatisés

**Caractéristiques :**
- Uniquement pour environnements dev/test
- Peuvent être régénérées
- Facilitent le développement et les tests
- Respectent le schéma mais pas critiques

## 📝 Format des fichiers

### Convention de nommage

```
[category]_[entity].sql

Exemples :
reference/countries.sql
reference/currencies.sql
reference/order_statuses.sql
sample/sample_suppliers.sql
sample/sample_purchase_orders.sql
```

### Structure d'un fichier seed

```sql
-- Seed: [nom_du_fichier]
-- Type: [reference|sample]
-- Description: Description des données
-- Dependencies: Liste des tables dépendantes
-- Created: YYYY-MM-DD
-- Author: Nom de l'auteur

-- Utiliser INSERT IGNORE ou INSERT ... ON DUPLICATE KEY UPDATE
-- pour permettre de rejouer les seeds sans erreur

START TRANSACTION;

-- Désactiver les foreign key checks si nécessaire
SET FOREIGN_KEY_CHECKS = 0;

-- Insertion des données
INSERT IGNORE INTO table_name (col1, col2, col3) VALUES
('value1', 'value2', 'value3'),
('value4', 'value5', 'value6');

-- Réactiver les foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

COMMIT;
```

## 📚 Exemples

### Données de référence - Pays

**Fichier** : `reference/countries.sql`

```sql
-- Seed: countries
-- Type: reference
-- Description: Liste des pays avec codes ISO
-- Dependencies: None
-- Created: 2024-12-21
-- Author: Procurement Team

START TRANSACTION;

CREATE TABLE IF NOT EXISTS countries (
    code VARCHAR(3) PRIMARY KEY COMMENT 'Code ISO 3166-1 alpha-3',
    name VARCHAR(100) NOT NULL,
    name_fr VARCHAR(100),
    alpha2 VARCHAR(2) UNIQUE COMMENT 'Code ISO 3166-1 alpha-2',
    region VARCHAR(50),
    subregion VARCHAR(50),
    INDEX idx_name (name),
    INDEX idx_region (region)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO countries (code, name, name_fr, alpha2, region, subregion) VALUES
('FRA', 'France', 'France', 'FR', 'Europe', 'Western Europe'),
('BEL', 'Belgium', 'Belgique', 'BE', 'Europe', 'Western Europe'),
('DEU', 'Germany', 'Allemagne', 'DE', 'Europe', 'Western Europe'),
('ESP', 'Spain', 'Espagne', 'ES', 'Europe', 'Southern Europe'),
('ITA', 'Italy', 'Italie', 'IT', 'Europe', 'Southern Europe'),
('GBR', 'United Kingdom', 'Royaume-Uni', 'GB', 'Europe', 'Northern Europe'),
('USA', 'United States', 'États-Unis', 'US', 'Americas', 'Northern America'),
('CAN', 'Canada', 'Canada', 'CA', 'Americas', 'Northern America'),
('CHN', 'China', 'Chine', 'CN', 'Asia', 'Eastern Asia'),
('JPN', 'Japan', 'Japon', 'JP', 'Asia', 'Eastern Asia');

COMMIT;
```

### Données de référence - Devises

**Fichier** : `reference/currencies.sql`

```sql
-- Seed: currencies
-- Type: reference
-- Description: Liste des devises avec codes ISO 4217
-- Dependencies: None
-- Created: 2024-12-21
-- Author: Procurement Team

START TRANSACTION;

CREATE TABLE IF NOT EXISTS currencies (
    code VARCHAR(3) PRIMARY KEY COMMENT 'Code ISO 4217',
    name VARCHAR(50) NOT NULL,
    symbol VARCHAR(10),
    decimal_places TINYINT DEFAULT 2,
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO currencies (code, name, symbol, decimal_places) VALUES
('EUR', 'Euro', '€', 2),
('USD', 'US Dollar', '$', 2),
('GBP', 'Pound Sterling', '£', 2),
('JPY', 'Japanese Yen', '¥', 0),
('CHF', 'Swiss Franc', 'CHF', 2),
('CAD', 'Canadian Dollar', 'CA$', 2),
('AUD', 'Australian Dollar', 'A$', 2),
('CNY', 'Chinese Yuan', '¥', 2);

COMMIT;
```

### Données de référence - Statuts

**Fichier** : `reference/order_statuses.sql`

```sql
-- Seed: order_statuses
-- Type: reference
-- Description: Statuts des bons de commande
-- Dependencies: None
-- Created: 2024-12-21
-- Author: Procurement Team

START TRANSACTION;

CREATE TABLE IF NOT EXISTS order_statuses (
    code VARCHAR(50) PRIMARY KEY,
    label VARCHAR(100) NOT NULL,
    label_fr VARCHAR(100),
    description TEXT,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    color VARCHAR(20) COMMENT 'Code couleur pour UI'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO order_statuses (code, label, label_fr, description, sort_order, color) VALUES
('draft', 'Draft', 'Brouillon', 'Order is being created', 1, '#6c757d'),
('submitted', 'Submitted', 'Soumise', 'Order submitted for approval', 2, '#0dcaf0'),
('approved', 'Approved', 'Approuvée', 'Order approved and ready to send', 3, '#198754'),
('sent', 'Sent', 'Envoyée', 'Order sent to supplier', 4, '#0d6efd'),
('confirmed', 'Confirmed', 'Confirmée', 'Order confirmed by supplier', 5, '#20c997'),
('partial', 'Partially Received', 'Partiellement reçue', 'Some items received', 6, '#ffc107'),
('received', 'Received', 'Reçue', 'All items received', 7, '#198754'),
('rejected', 'Rejected', 'Rejetée', 'Order rejected', 8, '#dc3545'),
('cancelled', 'Cancelled', 'Annulée', 'Order cancelled', 9, '#6c757d');

COMMIT;
```

### Données d'exemple - Fournisseurs

**Fichier** : `sample/sample_suppliers.sql`

```sql
-- Seed: sample_suppliers
-- Type: sample
-- Description: Fournisseurs fictifs pour dev/test
-- Dependencies: countries
-- Created: 2024-12-21
-- Author: Procurement Team
-- WARNING: DO NOT USE IN PRODUCTION

START TRANSACTION;

INSERT IGNORE INTO suppliers (id, name, code, email, phone, address, city, country, status) VALUES
(1, 'Acme Corp', 'SUP-001', 'contact@acme-corp.example.com', '+33 1 23 45 67 89', '123 Business Street', 'Paris', 'FRA', 'active'),
(2, 'Global Supplies Ltd', 'SUP-002', 'info@globalsupplies.example.com', '+44 20 1234 5678', '456 Commerce Road', 'London', 'GBR', 'active'),
(3, 'Tech Solutions GmbH', 'SUP-003', 'contact@techsolutions.example.de', '+49 30 12345678', '789 Technology Ave', 'Berlin', 'DEU', 'active'),
(4, 'Industrial Parts SA', 'SUP-004', 'sales@industrialparts.example.es', '+34 91 123 4567', '321 Industry Blvd', 'Madrid', 'ESP', 'active'),
(5, 'Quality Goods Inc', 'SUP-005', 'orders@qualitygoods.example.com', '+1 555 123 4567', '654 Quality Lane', 'New York', 'USA', 'inactive'),
(6, 'Reliable Vendor Co', 'SUP-006', 'info@reliablevendor.example.ca', '+1 416 555 0123', '987 Reliable Street', 'Toronto', 'CAN', 'active'),
(7, 'Fast Delivery Express', 'SUP-007', 'support@fastdelivery.example.com', '+33 4 56 78 90 12', '147 Speed Avenue', 'Lyon', 'FRA', 'active'),
(8, 'Premium Materials Ltd', 'SUP-008', 'contact@premiummaterials.example.it', '+39 02 1234567', '258 Premium Plaza', 'Milan', 'ITA', 'blocked'),
(9, 'Budget Supplier Co', 'SUP-009', 'sales@budgetsupplier.example.com', '+33 5 12 34 56 78', '369 Economy Road', 'Marseille', 'FRA', 'active'),
(10, 'Specialty Items GmbH', 'SUP-010', 'info@specialtyitems.example.de', '+49 89 87654321', '741 Specialty Street', 'Munich', 'DEU', 'active');

COMMIT;
```

### Données d'exemple - Commandes

**Fichier** : `sample/sample_purchase_orders.sql`

```sql
-- Seed: sample_purchase_orders
-- Type: sample
-- Description: Bons de commande fictifs pour dev/test
-- Dependencies: suppliers, currencies, order_statuses
-- Created: 2024-12-21
-- Author: Procurement Team
-- WARNING: DO NOT USE IN PRODUCTION

START TRANSACTION;

INSERT IGNORE INTO purchase_orders (
    id, order_number, supplier_id, status, total_amount, currency, 
    order_date, expected_delivery_date, notes
) VALUES
(1, 'PO-2024-001', 1, 'approved', 15000.00, 'EUR', '2024-01-15', '2024-02-15', 'Urgent order for office supplies'),
(2, 'PO-2024-002', 2, 'sent', 28500.50, 'GBP', '2024-01-20', '2024-03-01', 'Regular monthly order'),
(3, 'PO-2024-003', 3, 'confirmed', 42000.00, 'EUR', '2024-02-01', '2024-03-15', 'IT equipment for new office'),
(4, 'PO-2024-004', 1, 'partial', 8750.25, 'EUR', '2024-02-10', '2024-02-28', 'Stationery supplies'),
(5, 'PO-2024-005', 4, 'received', 19999.99, 'EUR', '2024-02-15', '2024-03-10', 'Industrial parts'),
(6, 'PO-2024-006', 6, 'draft', 5000.00, 'CAD', '2024-03-01', '2024-04-01', 'Draft order - pending approval'),
(7, 'PO-2024-007', 7, 'submitted', 12500.00, 'EUR', '2024-03-05', '2024-03-20', 'Express delivery required'),
(8, 'PO-2024-008', 9, 'approved', 3250.75, 'EUR', '2024-03-10', '2024-04-05', 'Budget items'),
(9, 'PO-2024-009', 10, 'sent', 67500.00, 'EUR', '2024-03-15', '2024-04-30', 'Specialty components'),
(10, 'PO-2024-010', 1, 'cancelled', 1500.00, 'EUR', '2024-03-20', '2024-04-15', 'Cancelled due to budget constraints');

COMMIT;
```

## 🚀 Utilisation

### Charger les données de référence

```bash
# Toutes les données de référence
for file in seeds/reference/*.sql; do
    echo "Loading $file..."
    mysql -u root -p procurement < "$file"
done

# Une fichier spécifique
mysql -u root -p procurement < seeds/reference/countries.sql
```

### Charger les données d'exemple (dev/test uniquement)

```bash
# Toutes les données d'exemple
for file in seeds/sample/*.sql; do
    echo "Loading $file..."
    mysql -u root -p procurement < "$file"
done

# Fichier spécifique
mysql -u root -p procurement < seeds/sample/sample_suppliers.sql
```

### Script automatisé

```bash
# Charger selon l'environnement
./scripts/load-seeds.sh --env development  # Charge reference + sample
./scripts/load-seeds.sh --env production   # Charge reference uniquement
```

## ✅ Bonnes pratiques

### 1. Idempotence

Utiliser `INSERT IGNORE` ou `ON DUPLICATE KEY UPDATE` :

```sql
-- ✅ Bon - peut être rejoué sans erreur
INSERT IGNORE INTO countries (code, name) VALUES ('FRA', 'France');

-- ✅ Bon - met à jour si existe
INSERT INTO countries (code, name) VALUES ('FRA', 'France')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- ❌ Mauvais - échoue si déjà présent
INSERT INTO countries (code, name) VALUES ('FRA', 'France');
```

### 2. Ordre de chargement

Respecter les dépendances :

```bash
# 1. Tables sans dépendances
mysql < seeds/reference/countries.sql
mysql < seeds/reference/currencies.sql

# 2. Tables avec dépendances
mysql < seeds/sample/sample_suppliers.sql  # Dépend de countries

# 3. Tables avec plusieurs dépendances
mysql < seeds/sample/sample_purchase_orders.sql  # Dépend de suppliers
```

### 3. IDs explicites

Pour les données de référence, utiliser des IDs explicites :

```sql
-- ✅ Bon pour données de référence - IDs prévisibles
INSERT INTO order_statuses (id, code, label) VALUES
(1, 'draft', 'Draft'),
(2, 'submitted', 'Submitted');

-- ✅ Bon pour données d'exemple - laisser auto-increment
INSERT INTO suppliers (name, code) VALUES
('Acme Corp', 'SUP-001');
```

### 4. Documentation

Toujours inclure un header descriptif :

```sql
-- Seed: [nom]
-- Type: [reference|sample]
-- Description: [description détaillée]
-- Dependencies: [liste des tables]
-- Created: [date]
-- Author: [auteur]
-- WARNING: [si sample] DO NOT USE IN PRODUCTION
```

### 5. Transactions

Utiliser des transactions pour l'atomicité :

```sql
START TRANSACTION;
-- insertions
COMMIT;
```

### 6. Encodage

Toujours UTF-8 :

```sql
-- En-tête du fichier
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
```

## 🔄 Maintenance

### Mise à jour des données de référence

```bash
# 1. Modifier le fichier seed
nano seeds/reference/countries.sql

# 2. Tester localement
mysql -u root -p procurement < seeds/reference/countries.sql

# 3. Commiter
git add seeds/reference/countries.sql
git commit -m "chore: update countries reference data"
```

### Regénérer les données d'exemple

```bash
# 1. Créer/modifier le fichier
nano seeds/sample/sample_suppliers.sql

# 2. Réinitialiser la base de test
mysql -u root -p procurement -e "TRUNCATE TABLE suppliers;"

# 3. Recharger
mysql -u root -p procurement < seeds/sample/sample_suppliers.sql
```

## ⚠️ Avertissements

### Production

❌ **JAMAIS** charger les données d'exemple en production
✅ **TOUJOURS** vérifier l'environnement avant de charger des seeds
✅ **TOUJOURS** sauvegarder avant de charger des données

### Sécurité

- Pas de données sensibles (même en sample)
- Pas de vrais emails/téléphones
- Pas de vraies adresses
- Utiliser `.example.com` pour les emails de test

### Performance

- Limiter la taille des fichiers sample
- Utiliser des transactions pour grandes quantités
- Désactiver les index avant gros chargements

## 📞 Support

- **Questions** : Créer une issue
- **Nouvelles données de référence** : PR avec justification
- **Données d'exemple** : Contributions bienvenues
