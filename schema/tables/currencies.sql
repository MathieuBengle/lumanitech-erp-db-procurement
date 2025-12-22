-- Table: currencies
-- Description: Codes ISO 4217 des devises
-- Owner: Procurement API

CREATE TABLE IF NOT EXISTS currencies (
    code VARCHAR(3) PRIMARY KEY COMMENT 'Code ISO 4217',
    name VARCHAR(50) NOT NULL,
    symbol VARCHAR(10),
    decimal_places TINYINT DEFAULT 2,
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Codes devises ISO 4217';
