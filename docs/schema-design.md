# Schema Design - Procurement Database

## 📋 Vue d'ensemble

Le schéma de la base de données Procurement est conçu pour gérer l'ensemble du cycle d'approvisionnement, de la demande d'achat à la réception des marchandises et la facturation.

## 🎯 Domaines fonctionnels

### 1. Gestion des fournisseurs (Suppliers)
- Informations de base des fournisseurs
- Coordonnées et adresses
- Statuts et évaluations
- Historique des relations

### 2. Catalogue et produits
- Articles achetables
- Catégories de produits
- Prix et conditions fournisseurs
- Unités de mesure

### 3. Processus d'achat
- Demandes d'achat (Purchase Requests)
- Bons de commande (Purchase Orders)
- Lignes de commande (Order Items)
- Workflow d'approbation

### 4. Réception et contrôle
- Réceptions de marchandises (Goods Receipts)
- Contrôle qualité
- Retours fournisseurs

### 5. Facturation fournisseurs
- Factures fournisseurs (Vendor Invoices)
- Rapprochement factures/commandes
- Suivi des paiements

### 6. Contrats et accords
- Contrats-cadres
- Conditions tarifaires
- Dates de validité

## 📊 Diagramme ERD (Entity-Relationship)

```
┌─────────────────┐
│   COUNTRIES     │
│─────────────────│
│ PK code         │
│    name         │
│    alpha2       │
└─────────────────┘
         │
         │ 1
         │
         │ N
┌─────────────────┐         ┌─────────────────────┐
│   SUPPLIERS     │────N────│  SUPPLIER_CONTACTS  │
│─────────────────│         │─────────────────────│
│ PK id           │         │ PK id               │
│    code         │         │ FK supplier_id      │
│    name         │         │    name             │
│    email        │         │    email            │
│    phone        │         │    phone            │
│    address      │         │    position         │
│    city         │         │    is_primary       │
│ FK country      │         └─────────────────────┘
│    status       │
│    created_at   │
│    updated_at   │
└─────────────────┘
         │
         │ 1
         │
         │ N
┌─────────────────────┐         ┌────────────────────┐
│  PURCHASE_ORDERS    │────N────│  ORDER_ITEMS       │
│─────────────────────│         │────────────────────│
│ PK id               │         │ PK id              │
│    order_number     │         │ FK order_id        │
│ FK supplier_id      │         │    item_code       │
│    status           │         │    description     │
│    total_amount     │         │    quantity        │
│    currency         │         │    unit_price      │
│    order_date       │         │    total_price     │
│    delivery_date    │         │    unit            │
│    notes            │         └────────────────────┘
│    created_at       │
│    updated_at       │
│ FK created_by       │
│ FK updated_by       │
└─────────────────────┘
         │
         │ 1
         │
         │ N
┌─────────────────────┐
│  GOODS_RECEIPTS     │
│─────────────────────│
│ PK id               │
│    receipt_number   │
│ FK order_id         │
│    receipt_date     │
│    received_by      │
│    status           │
│    notes            │
└─────────────────────┘
         │
         │ 1
         │
         │ N
┌─────────────────────┐
│  RECEIPT_ITEMS      │
│─────────────────────│
│ PK id               │
│ FK receipt_id       │
│ FK order_item_id    │
│    quantity_received│
│    quality_status   │
│    notes            │
└─────────────────────┘


┌─────────────────────┐         ┌────────────────────┐
│  VENDOR_INVOICES    │────N────│  INVOICE_ITEMS     │
│─────────────────────│         │────────────────────│
│ PK id               │         │ PK id              │
│    invoice_number   │         │ FK invoice_id      │
│ FK supplier_id      │         │ FK order_item_id   │
│ FK order_id         │         │    description     │
│    invoice_date     │         │    quantity        │
│    due_date         │         │    unit_price      │
│    total_amount     │         │    total_price     │
│    currency         │         └────────────────────┘
│    status           │
│    payment_date     │
└─────────────────────┘


┌─────────────────────┐
│  CURRENCIES         │
│─────────────────────│
│ PK code             │
│    name             │
│    symbol           │
│    decimal_places   │
└─────────────────────┘


┌─────────────────────┐
│  ORDER_STATUSES     │
│─────────────────────│
│ PK code             │
│    label            │
│    description      │
│    sort_order       │
└─────────────────────┘
```

## 🗂️ Tables principales

### suppliers

Stocke les informations sur les fournisseurs.

**Colonnes :**
- `id` : Identifiant unique
- `code` : Code fournisseur unique (format: SUP-XXX)
- `name` : Nom du fournisseur
- `email` : Email principal
- `phone` : Téléphone principal
- `address` : Adresse postale
- `city` : Ville
- `country` : Code pays (FK vers countries)
- `status` : Statut (active, inactive, blocked)
- `created_at`, `updated_at` : Timestamps
- `created_by`, `updated_by` : Audit

**Index :**
- `idx_code` : Recherche rapide par code
- `idx_name` : Recherche par nom
- `idx_status` : Filtrage par statut
- `idx_city_country` : Recherche géographique

### purchase_orders

Stocke les bons de commande.

**Colonnes :**
- `id` : Identifiant unique
- `order_number` : Numéro de commande unique (format: PO-YYYY-XXX)
- `supplier_id` : Fournisseur (FK vers suppliers)
- `status` : Statut de la commande
- `total_amount` : Montant total
- `currency` : Devise (FK vers currencies)
- `order_date` : Date de commande
- `expected_delivery_date` : Date de livraison prévue
- `notes` : Notes et commentaires
- `created_at`, `updated_at` : Timestamps
- `created_by`, `updated_by` : Audit

**Index :**
- `idx_order_number` : Recherche par numéro
- `idx_supplier` : Commandes par fournisseur
- `idx_status` : Filtrage par statut
- `idx_order_date` : Tri chronologique

### order_items

Lignes de commande détaillées.

**Colonnes :**
- `id` : Identifiant unique
- `order_id` : Bon de commande (FK vers purchase_orders)
- `item_code` : Code article
- `description` : Description de l'article
- `quantity` : Quantité commandée
- `unit_price` : Prix unitaire
- `total_price` : Prix total (quantity × unit_price)
- `unit` : Unité de mesure (pcs, kg, L, etc.)

**Index :**
- `idx_order` : Articles par commande
- `idx_item_code` : Recherche par code article

### goods_receipts

Réceptions de marchandises.

**Colonnes :**
- `id` : Identifiant unique
- `receipt_number` : Numéro de réception (format: GR-YYYY-XXX)
- `order_id` : Commande associée (FK vers purchase_orders)
- `receipt_date` : Date de réception
- `received_by` : Personne ayant réceptionné
- `status` : Statut (pending, completed, partial)
- `notes` : Notes

**Index :**
- `idx_receipt_number` : Recherche par numéro
- `idx_order` : Réceptions par commande
- `idx_date` : Tri chronologique

### vendor_invoices

Factures fournisseurs.

**Colonnes :**
- `id` : Identifiant unique
- `invoice_number` : Numéro de facture
- `supplier_id` : Fournisseur (FK vers suppliers)
- `order_id` : Commande associée (FK vers purchase_orders)
- `invoice_date` : Date de facturation
- `due_date` : Date d'échéance
- `total_amount` : Montant total
- `currency` : Devise
- `status` : Statut (pending, approved, paid, rejected)
- `payment_date` : Date de paiement

**Index :**
- `idx_invoice_number` : Recherche par numéro
- `idx_supplier` : Factures par fournisseur
- `idx_status` : Filtrage par statut
- `idx_due_date` : Tri par échéance

## 🔐 Règles métier

### Statuts des commandes

Workflow de statuts pour `purchase_orders.status` :

```
draft → submitted → approved → sent → confirmed → received
                        ↓
                    rejected
                        ↓
                    cancelled (depuis n'importe quel état)
```

**Règles :**
- Une commande en `draft` peut être modifiée
- Une fois `submitted`, nécessite approbation
- `approved` permet l'envoi au fournisseur
- `sent` = envoyée au fournisseur
- `confirmed` = confirmée par le fournisseur
- `received` = marchandises reçues
- `rejected` = refusée par l'approbateur
- `cancelled` = annulée (peut être depuis n'importe quel état)

### Validation des montants

- `order_items.total_price` doit égaler `quantity × unit_price`
- `purchase_orders.total_amount` doit égaler la somme des `order_items.total_price`
- Les montants sont stockés en `DECIMAL(15,2)` pour la précision

### Intégrité référentielle

- Un fournisseur avec des commandes ne peut pas être supprimé (ON DELETE RESTRICT)
- Une commande avec des lignes ne peut pas être supprimée
- Les codes (supplier.code, order_number) doivent être uniques

### Audit

Toutes les tables principales ont :
- `created_at` : Date de création (auto)
- `updated_at` : Date de dernière modification (auto)
- `created_by` : ID utilisateur créateur
- `updated_by` : ID utilisateur modificateur

## 🔍 Vues utiles

### active_suppliers_summary

Liste des fournisseurs actifs avec statistiques.

```sql
CREATE VIEW active_suppliers_summary AS
SELECT 
    s.id,
    s.code,
    s.name,
    s.email,
    s.city,
    s.country,
    COUNT(DISTINCT po.id) as total_orders,
    SUM(po.total_amount) as total_spent,
    MAX(po.order_date) as last_order_date
FROM suppliers s
LEFT JOIN purchase_orders po ON s.id = po.supplier_id
WHERE s.status = 'active'
GROUP BY s.id;
```

### pending_orders

Commandes en attente de traitement.

```sql
CREATE VIEW pending_orders AS
SELECT 
    po.id,
    po.order_number,
    s.name as supplier_name,
    po.status,
    po.total_amount,
    po.currency,
    po.order_date,
    po.expected_delivery_date,
    DATEDIFF(po.expected_delivery_date, CURDATE()) as days_until_delivery
FROM purchase_orders po
JOIN suppliers s ON po.supplier_id = s.id
WHERE po.status IN ('submitted', 'approved', 'sent', 'confirmed');
```

### invoice_matching

Rapprochement factures/commandes.

```sql
CREATE VIEW invoice_matching AS
SELECT 
    vi.invoice_number,
    vi.invoice_date,
    po.order_number,
    s.name as supplier_name,
    vi.total_amount as invoice_amount,
    po.total_amount as order_amount,
    (vi.total_amount - po.total_amount) as difference
FROM vendor_invoices vi
JOIN purchase_orders po ON vi.order_id = po.id
JOIN suppliers s ON vi.supplier_id = s.id;
```

## 🚀 Évolutions futures

### Phase 2 - Prévue

- **Catalogue produits** : Table dédiée aux articles
- **Contrats-cadres** : Gestion des accords à long terme
- **Multi-devises avancé** : Taux de change historiques
- **Workflow d'approbation** : Circuits de validation configurables
- **Documents** : Stockage des PDF (commandes, factures)

### Phase 3 - À définir

- **Gestion budgétaire** : Contrôle des budgets
- **Demandes d'achat** : Processus de demande avant commande
- **RFQ/RFP** : Appels d'offres
- **Performance fournisseurs** : KPIs et évaluations
- **Intégrations** : Connexions avec ERP, comptabilité

## 📚 Standards et conventions

### Nommage

- **Tables** : Pluriel, snake_case (suppliers, purchase_orders)
- **Colonnes** : Snake_case (supplier_id, created_at)
- **FK** : Nom de la table référencée + _id (supplier_id)
- **Index** : idx_table_column(s)
- **Vues** : Descriptives (active_suppliers_summary)

### Types de données

- **IDs** : BIGINT UNSIGNED AUTO_INCREMENT
- **Codes** : VARCHAR avec contrainte UNIQUE
- **Montants** : DECIMAL(15,2)
- **Dates** : DATE pour les dates, TIMESTAMP pour date+heure
- **Statuts** : ENUM ou VARCHAR avec table de référence
- **Texte** : VARCHAR pour court, TEXT pour long

### Encodage

- **Charset** : utf8mb4
- **Collation** : utf8mb4_unicode_ci
- **Engine** : InnoDB (pour les transactions et FK)

## 📞 Contact

Pour toute question sur le design du schéma :
- **Architecture** : DBA Team
- **Fonctionnel** : Procurement API Team
- **Issues** : GitHub repository
