-- Migration: V001_init_schema
-- Created: 2024-12-21
-- Author: Procurement Team
-- Description: Initialisation du schéma de base pour la base de données Procurement.
--              Création de la table schema_migrations pour le suivi des migrations,
--              et des tables de référence essentielles (countries, currencies).

START TRANSACTION;

-- ============================================================================
-- Table de suivi des migrations
-- ============================================================================

CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(50) PRIMARY KEY,
    description VARCHAR(255),
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_applied_at (applied_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Suivi des migrations appliquées';

-- ============================================================================
-- Tables de référence
-- ============================================================================

-- Table des pays (codes ISO 3166-1)
CREATE TABLE IF NOT EXISTS countries (
    code VARCHAR(3) PRIMARY KEY COMMENT 'Code ISO 3166-1 alpha-3',
    name VARCHAR(100) NOT NULL,
    name_fr VARCHAR(100),
    alpha2 VARCHAR(2) UNIQUE COMMENT 'Code ISO 3166-1 alpha-2',
    region VARCHAR(50),
    subregion VARCHAR(50),
    INDEX idx_name (name),
    INDEX idx_region (region)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Codes pays ISO 3166-1';

-- Table des devises (codes ISO 4217)
CREATE TABLE IF NOT EXISTS currencies (
    code VARCHAR(3) PRIMARY KEY COMMENT 'Code ISO 4217',
    name VARCHAR(50) NOT NULL,
    symbol VARCHAR(10),
    decimal_places TINYINT DEFAULT 2,
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Codes devises ISO 4217';

-- Table des statuts de commandes
CREATE TABLE IF NOT EXISTS order_statuses (
    code VARCHAR(50) PRIMARY KEY,
    label VARCHAR(100) NOT NULL,
    label_fr VARCHAR(100),
    description TEXT,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    color VARCHAR(20) COMMENT 'Code couleur pour UI',
    INDEX idx_sort_order (sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Statuts des bons de commande';

-- ============================================================================
-- Tables principales
-- ============================================================================

-- Table des fournisseurs
CREATE TABLE IF NOT EXISTS suppliers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL COMMENT 'Code fournisseur unique (ex: SUP-001)',
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(3),
    status ENUM('active', 'inactive', 'blocked') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED,
    updated_by BIGINT UNSIGNED,
    INDEX idx_code (code),
    INDEX idx_name (name),
    INDEX idx_status (status),
    INDEX idx_city_country (city, country),
    FOREIGN KEY (country) REFERENCES countries(code) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Informations sur les fournisseurs';

-- ============================================================================
-- Enregistrer la migration
-- ============================================================================

INSERT INTO schema_migrations (version, description) 
VALUES ('V001', 'init_schema')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;

COMMIT;
