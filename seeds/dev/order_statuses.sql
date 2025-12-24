-- Seed: order_statuses
-- Type: reference
-- Description: Purchase order statuses
-- Dependencies: None
-- Created: 2024-12-21
-- Author: Procurement Team

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

START TRANSACTION;

-- Insert order statuses
INSERT IGNORE INTO order_statuses (code, label, label_fr, description, sort_order, is_active, color) VALUES
('draft', 'Draft', 'Brouillon', 'Order is being created', 1, TRUE, '#6c757d'),
('submitted', 'Submitted', 'Soumise', 'Order submitted for approval', 2, TRUE, '#0dcaf0'),
('approved', 'Approved', 'Approuvée', 'Order approved and ready to send', 3, TRUE, '#198754'),
('sent', 'Sent', 'Envoyée', 'Order sent to supplier', 4, TRUE, '#0d6efd'),
('confirmed', 'Confirmed', 'Confirmée', 'Order confirmed by supplier', 5, TRUE, '#20c997'),
('partial', 'Partially Received', 'Partiellement reçue', 'Some items received', 6, TRUE, '#ffc107'),
('received', 'Received', 'Reçue', 'All items received', 7, TRUE, '#198754'),
('rejected', 'Rejected', 'Rejetée', 'Order rejected', 8, TRUE, '#dc3545'),
('cancelled', 'Cancelled', 'Annulée', 'Order cancelled', 9, TRUE, '#6c757d');

COMMIT;
