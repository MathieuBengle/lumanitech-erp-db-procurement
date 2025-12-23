-- Seed: currencies
-- Type: reference
-- Description: Liste des devises avec codes ISO 4217
-- Dependencies: None
-- Created: 2024-12-21
-- Author: Procurement Team

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

START TRANSACTION;

-- Insertion des principales devises
INSERT IGNORE INTO currencies (code, name, symbol, decimal_places) VALUES
('EUR', 'Euro', '€', 2),
('USD', 'US Dollar', '$', 2),
('GBP', 'Pound Sterling', '£', 2),
('JPY', 'Japanese Yen', '¥', 0),
('CHF', 'Swiss Franc', 'CHF', 2),
('CAD', 'Canadian Dollar', 'CA$', 2),
('AUD', 'Australian Dollar', 'A$', 2),
('CNY', 'Chinese Yuan', '¥', 2),
('INR', 'Indian Rupee', '₹', 2),
('BRL', 'Brazilian Real', 'R$', 2),
('MXN', 'Mexican Peso', '$', 2),
('KRW', 'South Korean Won', '₩', 0),
('SGD', 'Singapore Dollar', 'S$', 2),
('NZD', 'New Zealand Dollar', 'NZ$', 2),
('ZAR', 'South African Rand', 'R', 2),
('SEK', 'Swedish Krona', 'kr', 2),
('NOK', 'Norwegian Krone', 'kr', 2),
('DKK', 'Danish Krone', 'kr', 2),
('PLN', 'Polish Zloty', 'zł', 2),
('CZK', 'Czech Koruna', 'Kč', 2);

COMMIT;
