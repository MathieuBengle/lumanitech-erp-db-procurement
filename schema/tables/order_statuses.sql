-- Table: order_statuses
-- Description: Statuts des bons de commande
-- Owner: Procurement API

CREATE TABLE IF NOT EXISTS order_statuses (
    code VARCHAR(50) PRIMARY KEY,
    label VARCHAR(100) NOT NULL,
    label_fr VARCHAR(100),
    description TEXT,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    color VARCHAR(20),
    INDEX idx_sort_order (sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Statuts des bons de commande';
