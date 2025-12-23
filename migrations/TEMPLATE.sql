-- Migration: V###_description
-- Created: YYYY-MM-DD
-- Author: Your Name
-- Description: Detailed description of what this migration does.
--              Can span multiple lines to explain the purpose,
--              impact, and any important considerations.

-- Start transaction
START TRANSACTION;

-- ============================================================================
-- Your migration code here
-- ============================================================================

-- Example: Create a new table
-- CREATE TABLE IF NOT EXISTS example_table (
--     id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
--     name VARCHAR(255) NOT NULL,
--     description TEXT,
--     status ENUM('active', 'inactive') DEFAULT 'active',
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
--     INDEX idx_name (name),
--     INDEX idx_status (status)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
-- COMMENT='Brief description of the table purpose';

-- Example: Add a column to existing table
-- ALTER TABLE existing_table 
-- ADD COLUMN IF NOT EXISTS new_column VARCHAR(100) 
-- AFTER existing_column;

-- Example: Create an index
-- CREATE INDEX IF NOT EXISTS idx_table_column ON table_name(column_name);

-- Example: Insert reference data
-- INSERT IGNORE INTO reference_table (code, label, sort_order) VALUES
-- ('code1', 'Label 1', 1),
-- ('code2', 'Label 2', 2);

-- ============================================================================
-- Record migration in schema_migrations table
-- ============================================================================

INSERT INTO schema_migrations (version, description) 
VALUES ('V###', 'description')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;

-- Commit transaction
COMMIT;
