# Data Dictionary - Procurement Database

## 📋 Vue d'ensemble

Ce document décrit toutes les tables, colonnes, types de données, contraintes et relations de la base de données Procurement.

**Dernière mise à jour** : 2024-12-21
**Version du schéma** : 1.0.0

## 📊 Tables

### suppliers

**Description** : Informations sur les fournisseurs

**Type** : Table principale  
**Engine** : InnoDB  
**Charset** : utf8mb4_unicode_ci

| Colonne | Type | Null | Default | Index | Description |
|---------|------|------|---------|-------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Identifiant unique du fournisseur |
| code | VARCHAR(50) | NO | - | UNIQUE | Code fournisseur unique (format: SUP-XXX) |
| name | VARCHAR(255) | NO | - | INDEX | Nom commercial du fournisseur |
| email | VARCHAR(255) | YES | NULL | - | Adresse email principale |
| phone | VARCHAR(50) | YES | NULL | - | Numéro de téléphone principal |
| address | TEXT | YES | NULL | - | Adresse postale complète |
| city | VARCHAR(100) | YES | NULL | INDEX | Ville |
| country | VARCHAR(100) | YES | NULL | INDEX | Pays (code ISO 3166-1 alpha-3) |
| status | ENUM | NO | 'active' | INDEX | Statut: active, inactive, blocked |
| created_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | - | Date de création |
| updated_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | - | Date de dernière modification |
| created_by | BIGINT UNSIGNED | YES | NULL | - | ID utilisateur créateur |
| updated_by | BIGINT UNSIGNED | YES | NULL | - | ID utilisateur modificateur |

**Index :**
- `PRIMARY KEY` : id
- `UNIQUE KEY` : code
- `INDEX idx_name` : name
- `INDEX idx_status` : status
- `INDEX idx_city_country` : city, country

**Contraintes :**
- code doit être unique
- status doit être l'une des valeurs : 'active', 'inactive', 'blocked'

**Relations :**
- N purchase_orders via supplier_id
- N vendor_invoices via supplier_id

---

### purchase_orders

**Description** : Bons de commande aux fournisseurs

**Type** : Table principale  
**Engine** : InnoDB  
**Charset** : utf8mb4_unicode_ci

| Colonne | Type | Null | Default | Index | Description |
|---------|------|------|---------|-------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Identifiant unique de la commande |
| order_number | VARCHAR(50) | NO | - | UNIQUE | Numéro de commande unique (PO-YYYY-XXX) |
| supplier_id | BIGINT UNSIGNED | NO | - | FK, INDEX | Fournisseur (référence suppliers.id) |
| status | ENUM | NO | 'draft' | INDEX | Statut de la commande |
| total_amount | DECIMAL(15,2) | NO | 0.00 | - | Montant total TTC |
| currency | VARCHAR(3) | NO | 'EUR' | - | Code devise ISO 4217 |
| order_date | DATE | NO | - | INDEX | Date de la commande |
| expected_delivery_date | DATE | YES | NULL | - | Date de livraison prévue |
| notes | TEXT | YES | NULL | - | Notes et commentaires |
| created_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | - | Date de création |
| updated_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | - | Date de dernière modification |
| created_by | BIGINT UNSIGNED | YES | NULL | - | ID utilisateur créateur |
| updated_by | BIGINT UNSIGNED | YES | NULL | - | ID utilisateur modificateur |

**Index :**
- `PRIMARY KEY` : id
- `UNIQUE KEY` : order_number
- `INDEX idx_supplier` : supplier_id
- `INDEX idx_status` : status
- `INDEX idx_order_date` : order_date

**Contraintes :**
- `FOREIGN KEY` : supplier_id → suppliers(id) ON DELETE RESTRICT
- order_number doit être unique
- status: 'draft', 'submitted', 'approved', 'sent', 'confirmed', 'partial', 'received', 'rejected', 'cancelled'
- total_amount doit être >= 0

**Relations :**
- 1 supplier via supplier_id
- N order_items
- N goods_receipts
- N vendor_invoices

---

### order_items

**Description** : Lignes de commande (détail des articles commandés)

**Type** : Table de détail  
**Engine** : InnoDB  
**Charset** : utf8mb4_unicode_ci

| Colonne | Type | Null | Default | Index | Description |
|---------|------|------|---------|-------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Identifiant unique de la ligne |
| order_id | BIGINT UNSIGNED | NO | - | FK, INDEX | Bon de commande (référence purchase_orders.id) |
| item_code | VARCHAR(100) | NO | - | INDEX | Code/référence de l'article |
| description | TEXT | NO | - | - | Description de l'article |
| quantity | DECIMAL(10,3) | NO | - | - | Quantité commandée |
| unit_price | DECIMAL(15,2) | NO | - | - | Prix unitaire HT |
| total_price | DECIMAL(15,2) | NO | - | - | Prix total (quantity × unit_price) |
| unit | VARCHAR(20) | NO | 'pcs' | - | Unité de mesure (pcs, kg, L, m, etc.) |

**Index :**
- `PRIMARY KEY` : id
- `INDEX idx_order` : order_id
- `INDEX idx_item_code` : item_code

**Contraintes :**
- `FOREIGN KEY` : order_id → purchase_orders(id) ON DELETE CASCADE
- quantity doit être > 0
- unit_price doit être >= 0
- total_price doit être >= 0
- Règle calculée : total_price = quantity × unit_price

**Relations :**
- 1 purchase_order via order_id
- N receipt_items
- N invoice_items

---

### goods_receipts

**Description** : Réceptions de marchandises

**Type** : Table principale  
**Engine** : InnoDB  
**Charset** : utf8mb4_unicode_ci

| Colonne | Type | Null | Default | Index | Description |
|---------|------|------|---------|-------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Identifiant unique de la réception |
| receipt_number | VARCHAR(50) | NO | - | UNIQUE | Numéro de réception (GR-YYYY-XXX) |
| order_id | BIGINT UNSIGNED | NO | - | FK, INDEX | Commande associée |
| receipt_date | DATE | NO | - | INDEX | Date de réception |
| received_by | VARCHAR(255) | NO | - | - | Nom de la personne ayant réceptionné |
| status | ENUM | NO | 'pending' | INDEX | Statut: pending, completed, partial |
| notes | TEXT | YES | NULL | - | Notes et observations |
| created_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | - | Date de création |
| updated_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | - | Date de dernière modification |

**Index :**
- `PRIMARY KEY` : id
- `UNIQUE KEY` : receipt_number
- `INDEX idx_order` : order_id
- `INDEX idx_date` : receipt_date
- `INDEX idx_status` : status

**Contraintes :**
- `FOREIGN KEY` : order_id → purchase_orders(id) ON DELETE RESTRICT
- receipt_number doit être unique
- status: 'pending', 'completed', 'partial'

**Relations :**
- 1 purchase_order via order_id
- N receipt_items

---

### receipt_items

**Description** : Détail des articles reçus

**Type** : Table de détail  
**Engine** : InnoDB  
**Charset** : utf8mb4_unicode_ci

| Colonne | Type | Null | Default | Index | Description |
|---------|------|------|---------|-------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Identifiant unique |
| receipt_id | BIGINT UNSIGNED | NO | - | FK, INDEX | Réception associée |
| order_item_id | BIGINT UNSIGNED | NO | - | FK, INDEX | Ligne de commande associée |
| quantity_received | DECIMAL(10,3) | NO | - | - | Quantité effectivement reçue |
| quality_status | ENUM | NO | 'ok' | - | Statut qualité: ok, damaged, rejected |
| notes | TEXT | YES | NULL | - | Notes sur la réception |

**Index :**
- `PRIMARY KEY` : id
- `INDEX idx_receipt` : receipt_id
- `INDEX idx_order_item` : order_item_id

**Contraintes :**
- `FOREIGN KEY` : receipt_id → goods_receipts(id) ON DELETE CASCADE
- `FOREIGN KEY` : order_item_id → order_items(id) ON DELETE RESTRICT
- quantity_received doit être >= 0
- quality_status: 'ok', 'damaged', 'rejected'

**Relations :**
- 1 goods_receipt via receipt_id
- 1 order_item via order_item_id

---

### vendor_invoices

**Description** : Factures fournisseurs

**Type** : Table principale  
**Engine** : InnoDB  
**Charset** : utf8mb4_unicode_ci

| Colonne | Type | Null | Default | Index | Description |
|---------|------|------|---------|-------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Identifiant unique de la facture |
| invoice_number | VARCHAR(50) | NO | - | UNIQUE | Numéro de facture fournisseur |
| supplier_id | BIGINT UNSIGNED | NO | - | FK, INDEX | Fournisseur |
| order_id | BIGINT UNSIGNED | YES | NULL | FK, INDEX | Commande associée (optionnel) |
| invoice_date | DATE | NO | - | INDEX | Date de facturation |
| due_date | DATE | NO | - | INDEX | Date d'échéance de paiement |
| total_amount | DECIMAL(15,2) | NO | - | - | Montant total TTC |
| currency | VARCHAR(3) | NO | 'EUR' | - | Code devise ISO 4217 |
| status | ENUM | NO | 'pending' | INDEX | Statut de la facture |
| payment_date | DATE | YES | NULL | - | Date de paiement effectif |
| notes | TEXT | YES | NULL | - | Notes |
| created_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | - | Date de création |
| updated_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | - | Date de dernière modification |

**Index :**
- `PRIMARY KEY` : id
- `UNIQUE KEY` : invoice_number
- `INDEX idx_supplier` : supplier_id
- `INDEX idx_order` : order_id
- `INDEX idx_invoice_date` : invoice_date
- `INDEX idx_due_date` : due_date
- `INDEX idx_status` : status

**Contraintes :**
- `FOREIGN KEY` : supplier_id → suppliers(id) ON DELETE RESTRICT
- `FOREIGN KEY` : order_id → purchase_orders(id) ON DELETE SET NULL
- invoice_number doit être unique
- status: 'pending', 'approved', 'paid', 'rejected', 'disputed'
- total_amount doit être >= 0

**Relations :**
- 1 supplier via supplier_id
- 1 purchase_order via order_id (optionnel)
- N invoice_items

---

### invoice_items

**Description** : Lignes de facture fournisseur

**Type** : Table de détail  
**Engine** : InnoDB  
**Charset** : utf8mb4_unicode_ci

| Colonne | Type | Null | Default | Index | Description |
|---------|------|------|---------|-------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Identifiant unique |
| invoice_id | BIGINT UNSIGNED | NO | - | FK, INDEX | Facture associée |
| order_item_id | BIGINT UNSIGNED | YES | NULL | FK, INDEX | Ligne de commande associée (optionnel) |
| description | TEXT | NO | - | - | Description de l'article facturé |
| quantity | DECIMAL(10,3) | NO | - | - | Quantité facturée |
| unit_price | DECIMAL(15,2) | NO | - | - | Prix unitaire HT |
| total_price | DECIMAL(15,2) | NO | - | - | Prix total ligne |

**Index :**
- `PRIMARY KEY` : id
- `INDEX idx_invoice` : invoice_id
- `INDEX idx_order_item` : order_item_id

**Contraintes :**
- `FOREIGN KEY` : invoice_id → vendor_invoices(id) ON DELETE CASCADE
- `FOREIGN KEY` : order_item_id → order_items(id) ON DELETE SET NULL
- quantity doit être > 0
- unit_price doit être >= 0
- total_price doit être >= 0
- Règle calculée : total_price = quantity × unit_price

**Relations :**
- 1 vendor_invoice via invoice_id
- 1 order_item via order_item_id (optionnel)

---

## 📚 Tables de référence

### countries

**Description** : Codes pays ISO 3166-1

| Colonne | Type | Description |
|---------|------|-------------|
| code | VARCHAR(3) PK | Code ISO 3166-1 alpha-3 (ex: FRA) |
| name | VARCHAR(100) | Nom anglais du pays |
| name_fr | VARCHAR(100) | Nom français du pays |
| alpha2 | VARCHAR(2) UNIQUE | Code ISO 3166-1 alpha-2 (ex: FR) |
| region | VARCHAR(50) | Région (ex: Europe, Asia) |
| subregion | VARCHAR(50) | Sous-région (ex: Western Europe) |

---

### currencies

**Description** : Codes devises ISO 4217

| Colonne | Type | Description |
|---------|------|-------------|
| code | VARCHAR(3) PK | Code ISO 4217 (ex: EUR, USD) |
| name | VARCHAR(50) | Nom de la devise |
| symbol | VARCHAR(10) | Symbole (ex: €, $) |
| decimal_places | TINYINT | Nombre de décimales (généralement 2) |

---

### order_statuses

**Description** : Statuts des commandes

| Colonne | Type | Description |
|---------|------|-------------|
| code | VARCHAR(50) PK | Code du statut |
| label | VARCHAR(100) | Libellé anglais |
| label_fr | VARCHAR(100) | Libellé français |
| description | TEXT | Description détaillée |
| sort_order | INT | Ordre d'affichage |
| color | VARCHAR(20) | Code couleur pour UI |

**Valeurs :**
- draft : Brouillon
- submitted : Soumise pour approbation
- approved : Approuvée
- sent : Envoyée au fournisseur
- confirmed : Confirmée par fournisseur
- partial : Partiellement reçue
- received : Totalement reçue
- rejected : Rejetée
- cancelled : Annulée

---

### schema_migrations

**Description** : Suivi des migrations appliquées

| Colonne | Type | Description |
|---------|------|-------------|
| version | VARCHAR(50) PK | Numéro de version (ex: V001) |
| description | VARCHAR(255) | Description de la migration |
| applied_at | TIMESTAMP | Date d'application |

---

## 🔗 Diagramme de relations

```
countries 1──N suppliers 1──N purchase_orders 1──N order_items
                                  │                      │
                                  1                      │
                                  │                      │
                                  N                      1
                           goods_receipts 1──N receipt_items
                                  
suppliers 1──N vendor_invoices 1──N invoice_items
                      │
                      1
                      │
                      N (optional)
              purchase_orders
```

## 📖 Glossaire

**Termes métier :**

- **Supplier** : Fournisseur - Entreprise ou personne qui fournit des biens ou services
- **Purchase Order (PO)** : Bon de commande - Document officiel de commande
- **Goods Receipt (GR)** : Réception de marchandises - Acte de réception physique
- **Vendor Invoice** : Facture fournisseur - Document de facturation du fournisseur
- **Three-way matching** : Rapprochement trois voies - Vérification PO/GR/Invoice

**Termes techniques :**

- **FK** : Foreign Key (Clé étrangère)
- **PK** : Primary Key (Clé primaire)
- **HT** : Hors Taxes
- **TTC** : Toutes Taxes Comprises

## 📊 Règles de calcul

### Montants des commandes

```sql
-- Total d'une ligne de commande
order_items.total_price = order_items.quantity × order_items.unit_price

-- Total d'une commande
purchase_orders.total_amount = SUM(order_items.total_price) 
WHERE order_items.order_id = purchase_orders.id
```

### Montants des factures

```sql
-- Total d'une ligne de facture
invoice_items.total_price = invoice_items.quantity × invoice_items.unit_price

-- Total d'une facture
vendor_invoices.total_amount = SUM(invoice_items.total_price)
WHERE invoice_items.invoice_id = vendor_invoices.id
```

### Quantités reçues

```sql
-- Total reçu pour une ligne de commande
received_quantity = SUM(receipt_items.quantity_received)
WHERE receipt_items.order_item_id = order_items.id

-- Statut de réception d'une commande
IF received_quantity = 0 THEN 'not_received'
ELSE IF received_quantity < order_items.quantity THEN 'partial'
ELSE IF received_quantity = order_items.quantity THEN 'received'
ELSE 'over_received'
```

## 📞 Support

Pour des questions sur le dictionnaire de données :
- Ouvrir une issue sur GitHub
- Contacter l'équipe DBA
- Consulter la documentation dans `/docs/`
