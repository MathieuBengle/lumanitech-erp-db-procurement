-- Seed: sample_suppliers
-- Type: sample
-- Description: Fictitious suppliers for development and testing
-- Dependencies: suppliers table, countries
-- Created: 2024-12-21
-- Author: Procurement Team
-- WARNING: DO NOT USE IN PRODUCTION - SAMPLE DATA ONLY

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

START TRANSACTION;

-- Insert fictitious suppliers
INSERT IGNORE INTO suppliers (id, code, name, email, phone, address, city, country, status) VALUES
(1, 'SUP-001', 'Acme Corporation', 'contact@acme-corp.example.com', '+33 1 23 45 67 89', '123 Business Avenue', 'Paris', 'FRA', 'active'),
(2, 'SUP-002', 'Global Supplies Ltd', 'info@globalsupplies.example.com', '+44 20 1234 5678', '456 Commerce Street', 'London', 'GBR', 'active'),
(3, 'SUP-003', 'Tech Solutions GmbH', 'sales@techsolutions.example.de', '+49 30 12345678', '789 Technology Boulevard', 'Berlin', 'DEU', 'active'),
(4, 'SUP-004', 'Industrial Parts SA', 'orders@industrialparts.example.es', '+34 91 123 4567', '321 Industry Road', 'Madrid', 'ESP', 'active'),
(5, 'SUP-005', 'Quality Goods Inc', 'support@qualitygoods.example.com', '+1 555 123 4567', '654 Quality Lane', 'New York', 'USA', 'inactive'),
(6, 'SUP-006', 'Reliable Vendor Co', 'info@reliablevendor.example.ca', '+1 416 555 0123', '987 Reliable Street', 'Toronto', 'CAN', 'active'),
(7, 'SUP-007', 'Fast Delivery Express', 'contact@fastdelivery.example.fr', '+33 4 56 78 90 12', '147 Speed Avenue', 'Lyon', 'FRA', 'active'),
(8, 'SUP-008', 'Premium Materials Ltd', 'sales@premiummaterials.example.it', '+39 02 1234567', '258 Premium Plaza', 'Milan', 'ITA', 'blocked'),
(9, 'SUP-009', 'Budget Supplier Co', 'budget@budgetsupplier.example.fr', '+33 5 12 34 56 78', '369 Economy Road', 'Marseille', 'FRA', 'active'),
(10, 'SUP-010', 'Specialty Items GmbH', 'info@specialtyitems.example.de', '+49 89 87654321', '741 Specialty Street', 'Munich', 'DEU', 'active');

COMMIT;
