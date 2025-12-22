-- Table: suppliers
-- Description: Informations sur les fournisseurs
-- Owner: Procurement API

CREATE TABLE IF NOT EXISTS suppliers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL COMMENT 'Code fournisseur (SUP-xxx)',
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
COMMENT='Infos fournisseurs';
