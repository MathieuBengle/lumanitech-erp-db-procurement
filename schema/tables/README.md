# Tables

Ce dossier contient les définitions complètes des tables de la base de données.

## Format

Un fichier par table, nommé `table_name.sql`

## Mise à jour

Ces fichiers doivent être mis à jour après chaque migration qui modifie la structure d'une table.

Extraction automatique :
```bash
mysqldump -u root -p --no-data procurement table_name > tables/table_name.sql
```
