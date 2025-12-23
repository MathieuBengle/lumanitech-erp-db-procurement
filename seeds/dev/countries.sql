-- Seed: countries
-- Type: reference
-- Description: Liste des pays avec codes ISO 3166-1
-- Dependencies: None
-- Created: 2024-12-21
-- Author: Procurement Team

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

START TRANSACTION;

-- Insertion des pays principaux
INSERT IGNORE INTO countries (code, name, name_fr, alpha2, region, subregion) VALUES
-- Europe
('FRA', 'France', 'France', 'FR', 'Europe', 'Western Europe'),
('BEL', 'Belgium', 'Belgique', 'BE', 'Europe', 'Western Europe'),
('DEU', 'Germany', 'Allemagne', 'DE', 'Europe', 'Western Europe'),
('ESP', 'Spain', 'Espagne', 'ES', 'Europe', 'Southern Europe'),
('ITA', 'Italy', 'Italie', 'IT', 'Europe', 'Southern Europe'),
('GBR', 'United Kingdom', 'Royaume-Uni', 'GB', 'Europe', 'Northern Europe'),
('CHE', 'Switzerland', 'Suisse', 'CH', 'Europe', 'Western Europe'),
('NLD', 'Netherlands', 'Pays-Bas', 'NL', 'Europe', 'Western Europe'),
('PRT', 'Portugal', 'Portugal', 'PT', 'Europe', 'Southern Europe'),
('POL', 'Poland', 'Pologne', 'PL', 'Europe', 'Eastern Europe'),

-- Americas
('USA', 'United States', 'États-Unis', 'US', 'Americas', 'Northern America'),
('CAN', 'Canada', 'Canada', 'CA', 'Americas', 'Northern America'),
('MEX', 'Mexico', 'Mexique', 'MX', 'Americas', 'Central America'),
('BRA', 'Brazil', 'Brésil', 'BR', 'Americas', 'South America'),

-- Asia
('CHN', 'China', 'Chine', 'CN', 'Asia', 'Eastern Asia'),
('JPN', 'Japan', 'Japon', 'JP', 'Asia', 'Eastern Asia'),
('IND', 'India', 'Inde', 'IN', 'Asia', 'Southern Asia'),
('KOR', 'South Korea', 'Corée du Sud', 'KR', 'Asia', 'Eastern Asia'),
('SGP', 'Singapore', 'Singapour', 'SG', 'Asia', 'South-Eastern Asia'),

-- Oceania
('AUS', 'Australia', 'Australie', 'AU', 'Oceania', 'Australia and New Zealand'),
('NZL', 'New Zealand', 'Nouvelle-Zélande', 'NZ', 'Oceania', 'Australia and New Zealand'),

-- Africa
('ZAF', 'South Africa', 'Afrique du Sud', 'ZA', 'Africa', 'Southern Africa'),
('EGY', 'Egypt', 'Égypte', 'EG', 'Africa', 'Northern Africa'),
('MAR', 'Morocco', 'Maroc', 'MA', 'Africa', 'Northern Africa');

COMMIT;
