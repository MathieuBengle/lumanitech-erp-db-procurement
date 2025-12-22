# Lumanitech ERP - Procurement Database

Base de données pour le module d'approvisionnement du système ERP Lumanitech.

## 📋 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Structure du repository](#structure-du-repository)
- [Stratégie de migration](#stratégie-de-migration)
- [Ownership et responsabilité](#ownership-et-responsabilité)
- [Guide d'utilisation](#guide-dutilisation)
- [Validation CI/CD](#validation-cicd)
- [Contribution](#contribution)

## 🎯 Vue d'ensemble

Ce repository contient **uniquement** les définitions de schéma, migrations, et données de référence pour le module Procurement. Il ne contient **aucun code applicatif**.

### Périmètre fonctionnel

Le module Procurement gère :
- Gestion des fournisseurs (suppliers)
- Demandes d'achat (purchase requests)
- Bons de commande (purchase orders)
- Réceptions de marchandises (goods receipts)
- Factures fournisseurs (vendor invoices)
- Contrats et accords-cadres (contracts & agreements)

## 📁 Structure du repository

```
lumanitech-erp-db-procurement/
├── migrations/          # Scripts de migration versionnés (forward-only)
│   ├── README.md       # Guide des migrations
│   └── VXXX_*.sql     # Fichiers de migration (ex: V001_init_schema.sql)
├── schema/             # Définition du schéma actuel
│   ├── README.md      # Documentation du schéma
│   ├── tables/        # Définitions des tables
│   ├── views/         # Vues SQL
│   ├── procedures/    # Procédures stockées
│   ├── functions/     # Fonctions SQL
│   └── triggers/      # Triggers
├── seeds/              # Données de référence et exemples
│   ├── README.md      # Guide des seeds
│   ├── reference/     # Données de référence (pays, devises, etc.)
│   └── sample/        # Données d'exemple pour dev/test
├── docs/               # Documentation
│   ├── schema-design.md    # Design du schéma
│   ├── data-dictionary.md  # Dictionnaire de données
│   └── migration-guide.md  # Guide de migration détaillé
├── scripts/            # Scripts d'automatisation et validation
│   ├── validate-migrations.sh  # Validation des migrations
│   ├── check-syntax.sh        # Vérification syntaxe SQL
│   └── apply-migrations.sh    # Application des migrations
└── README.md           # Ce fichier
```

## 🔄 Stratégie de migration

### Principe : Forward-Only

Ce repository utilise une **stratégie de migration forward-only** (unidirectionnelle) :

✅ **Autorisé :**
- Migrations qui ajoutent de nouvelles structures (tables, colonnes, indexes)
- Migrations qui modifient des données
- Migrations qui créent de nouvelles contraintes

❌ **Interdit :**
- Fichiers de rollback (`*_down.sql`, `*_rollback.sql`)
- Suppression de colonnes sans migration de correction
- Modifications destructives sans plan de récupération

### Convention de nommage

Les migrations suivent le format : `VXXX_description.sql`

Où :
- `V` : Préfixe obligatoire pour "Version"
- `XXX` : Numéro séquentiel à 3 chiffres (001, 002, 003, ...)
- `description` : Description courte en snake_case (anglais recommandé)

**Exemples :**
```
V001_init_schema.sql
V002_add_suppliers_table.sql
V003_add_purchase_orders_table.sql
V004_add_audit_columns.sql
V005_create_reporting_views.sql
```

### Règles importantes

1. **Séquentialité** : Les migrations sont appliquées dans l'ordre numérique
2. **Immutabilité** : Une fois mergée en `main`, une migration ne doit JAMAIS être modifiée
3. **Correction par ajout** : Pour corriger une erreur, créer une nouvelle migration
4. **Idempotence** : Utiliser `IF NOT EXISTS` et `IF EXISTS` quand approprié
5. **Transactions** : Chaque migration doit être transactionnelle quand possible

### Template de migration

```sql
-- Migration: VXXX_description
-- Created: YYYY-MM-DD
-- Author: Nom de l'auteur
-- Description: Description détaillée de la migration

-- Start transaction (if supported for DDL)
START TRANSACTION;

-- Your migration code here
-- Use IF NOT EXISTS for safety
CREATE TABLE IF NOT EXISTS example (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Commit transaction
COMMIT;
```

## 👥 Ownership et responsabilité

### Propriété du schéma

Ce repository de base de données est **possédé et maintenu par l'équipe API Backend**.

### Modèle de responsabilité

```
┌─────────────────────────────────────┐
│   Procurement API (Owner)          │
│   - Définit les besoins métier     │
│   - Propose les évolutions schema  │
│   - Consomme la base de données    │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│   DB Repository (Ce repo)           │
│   - Stocke les migrations SQL      │
│   - Documente le schéma            │
│   - Valide la cohérence            │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│   MySQL Database Server             │
│   - Exécute les migrations         │
│   - Héberge les données            │
└─────────────────────────────────────┘
```

### Workflow de modification

1. **Proposition** : L'équipe API propose une modification via PR
2. **Review** : Review par les pairs (DB team + API team)
3. **Validation** : CI valide la syntaxe et la séquence
4. **Merge** : Fusion dans `main` après approbation
5. **Déploiement** : Application automatique ou manuelle selon l'environnement

### Points de contact

- **Owner** : Procurement API Team
- **DBA Support** : Database Administration Team
- **Questions** : Créer une issue dans ce repository

## 📖 Guide d'utilisation

### Prérequis

- MySQL 8.0+
- Client MySQL (mysql-client, MySQL Workbench, DBeaver, etc.)
- Git

### Installation locale

```bash
# 1. Cloner le repository
git clone https://github.com/MathieuBengle/lumanitech-erp-db-procurement.git
cd lumanitech-erp-db-procurement

# 2. Créer la base de données (privilèges root ou DBA requis)
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS procurement CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 3. Rendre les scripts exécutables
chmod +x ./scripts/deploy.sh ./scripts/apply-migrations.sh

# 4. Stocker les identifiants via mysql_config_editor (script utilise l'utilisateur admin)
mysql_config_editor set --login-path=local \
    --host=localhost \
    --user=admin \
    --password

# 5. Déployer schéma, migrations et données d'exemple
./scripts/deploy.sh --login-path=local --with-seeds
```

La commande `deploy.sh` orchestre la création des objets (`schema/tables`, `schema/views`, `procedures`, `functions`, `triggers`), l'exécution de toutes les migrations versionnées et, si l'option `--with-seeds` est fournie, l'injection des jeux de données `seeds/reference` et `seeds/sample`. Retirez `--with-seeds` si vous ne voulez pas recharger les données d'exemple.

### Création d'une nouvelle migration

```bash
# 1. Créer le fichier de migration avec le prochain numéro
cd migrations
# Vérifier le dernier numéro utilisé
ls -1 V*.sql | tail -1
# Créer la nouvelle migration
touch V00X_your_description.sql

# 2. Éditer le fichier avec votre SQL
# Suivre le template de migration

# 3. Tester localement
mysql -u root -p procurement < V00X_your_description.sql

# 4. Valider
../scripts/validate-migrations.sh

# 5. Créer une PR
git checkout -b feat/add-migration-X
git add V00X_your_description.sql
git commit -m "feat: add migration X for [description]"
git push origin feat/add-migration-X
```

### Application des migrations

#### Manuellement

```bash
# Appliquer toutes les migrations
for file in migrations/V*.sql; do
    echo "Applying $file..."
    mysql -u root -p procurement < "$file"
done
```

#### Avec le script

```bash
./scripts/apply-migrations.sh --database procurement --user admin --login-path=local
```

Le script `apply-migrations.sh` sait maintenant réutiliser la même `login-path=local` que `deploy.sh`, ce qui évite de passer les mots de passe en clair. Si vous n'utilisez pas de login path, il vous invite à saisir le mot de passe.

### Chargement des données de référence

```bash
# Charger les données de référence
mysql -u root -p procurement < seeds/reference/countries.sql
mysql -u root -p procurement < seeds/reference/currencies.sql

# Charger les données d'exemple (dev/test uniquement)
mysql -u root -p procurement < seeds/sample/sample_suppliers.sql
```

## ✅ Validation CI/CD

### Scripts de validation

Ce repository inclut plusieurs scripts de validation exécutés automatiquement en CI :

#### 1. Validation des migrations (`validate-migrations.sh`)

Vérifie :
- ✅ Nomenclature correcte (`VXXX_*.sql`)
- ✅ Séquence numérique sans trou
- ✅ Pas de doublons
- ✅ Pas de fichiers de rollback

```bash
./scripts/validate-migrations.sh
```

#### 2. Validation de syntaxe SQL (`check-syntax.sh`)

Vérifie :
- ✅ Syntaxe SQL valide (via mysqlcheck ou parser SQL)
- ✅ Pas d'instructions dangereuses en production
- ✅ Respect des conventions de nommage

```bash
./scripts/check-syntax.sh
```

### Pipeline CI

Le pipeline CI exécute automatiquement :

```yaml
# Exemple de pipeline (.github/workflows/validate.yml)
- Checkout code
- Install MySQL client
- Run validate-migrations.sh
- Run check-syntax.sh
- Dry-run migrations sur DB de test
```

### Pré-commit hooks (recommandé)

```bash
# Installer les hooks locaux
cp scripts/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## 🤝 Contribution

### Règles de contribution

1. **Toujours créer une branche** depuis `main`
2. **Nom de branche** : `feat/migration-XXX-description` ou `fix/migration-XXX-description`
3. **Une migration par PR** (sauf migrations fortement liées)
4. **Description claire** du besoin métier
5. **Tests locaux** avant de pousser
6. **Review obligatoire** par au moins 1 pair

### Checklist PR

- [ ] Migration testée localement
- [ ] Nomenclature respectée (`VXXX_*.sql`)
- [ ] Numéro séquentiel correct
- [ ] Scripts de validation passent
- [ ] Documentation mise à jour si nécessaire
- [ ] Description claire du changement

### Types de commits

- `feat`: Nouvelle migration (nouvelle fonctionnalité)
- `fix`: Migration corrective
- `docs`: Mise à jour documentation
- `chore`: Maintenance, scripts

## 📚 Documentation additionnelle

- [Design du schéma](docs/schema-design.md)
- [Dictionnaire de données](docs/data-dictionary.md)
- [Guide de migration détaillé](docs/migration-guide.md)

## 📄 Licence

Propriétaire - Lumanitech © 2024

---

**Note** : Ce repository contient uniquement du SQL. Pour le code applicatif, voir le repository de l'API Procurement.
