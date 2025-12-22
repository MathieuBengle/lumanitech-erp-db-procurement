-- Table: countries
-- Description: Liste des pays avec codes ISO 3166-1
-- Owner: Procurement API

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
