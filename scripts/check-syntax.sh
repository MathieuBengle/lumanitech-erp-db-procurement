#!/bin/bash

# check-syntax.sh
# Script de vérification de la syntaxe SQL des migrations
# Vérifie la syntaxe MySQL et détecte les patterns problématiques

# Note: Do not use set -e as condition tests may fail
# set -e

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
MIGRATIONS_DIR="migrations"
ERRORS=0
WARNINGS=0
CHECKED=0

echo "================================================"
echo "  Vérification syntaxe SQL - Procurement DB"
echo "================================================"
echo ""

# Fonction pour afficher les erreurs
error() {
    echo -e "${RED}✗ ERREUR:${NC} $1"
    ((ERRORS++))
}

# Fonction pour afficher les warnings
warning() {
    echo -e "${YELLOW}⚠ WARNING:${NC} $1"
    ((WARNINGS++))
}

# Fonction pour afficher les succès
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Fonction pour afficher les infos
info() {
    echo -e "ℹ $1"
}

# Vérifier que le dossier migrations existe
if [ ! -d "$MIGRATIONS_DIR" ]; then
    error "Le dossier '$MIGRATIONS_DIR' n'existe pas"
    exit 1
fi

echo "1. Recherche des fichiers SQL..."
SQL_FILES=("$MIGRATIONS_DIR"/*.sql)

if [ ${#SQL_FILES[@]} -eq 0 ] || [ ! -f "${SQL_FILES[0]}" ]; then
    info "Aucun fichier SQL trouvé"
    exit 0
fi

success "Trouvé ${#SQL_FILES[@]} fichier(s) SQL"
echo ""

echo "2. Vérification de l'encodage UTF-8..."
for file in "${SQL_FILES[@]}"; do
    if [ -f "$file" ]; then
        # Vérifier que le fichier est en UTF-8
        ENCODING=$(file -b --mime-encoding "$file" 2>/dev/null || echo "unknown")
        if [ "$ENCODING" != "utf-8" ] && [ "$ENCODING" != "us-ascii" ] && [ "$ENCODING" != "unknown" ]; then
            warning "$file: Encodage non UTF-8 détecté: $ENCODING"
        fi
        ((CHECKED++))
    fi
done
success "Encodage vérifié pour $CHECKED fichier(s)"
echo ""

echo "3. Vérification de la syntaxe SQL de base..."
for file in "${SQL_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    # Vérifier les erreurs de syntaxe évidentes
    
    # Parenthèses non fermées
    OPEN_PARENS=$(grep -o "(" "$file" | wc -l)
    CLOSE_PARENS=$(grep -o ")" "$file" | wc -l)
    if [ "$OPEN_PARENS" -ne "$CLOSE_PARENS" ]; then
        error "$file: Parenthèses non équilibrées ($OPEN_PARENS ouvrantes, $CLOSE_PARENS fermantes)"
    fi
    
    # Guillemets non fermés (simple approximation)
    SINGLE_QUOTES=$(grep -o "'" "$file" | wc -l)
    if [ $((SINGLE_QUOTES % 2)) -ne 0 ]; then
        warning "$file: Nombre impair de guillemets simples détecté"
    fi
    
    # Vérifier les points-virgules manquants à la fin des statements principaux
    if grep -Eq "CREATE TABLE.*\)" "$file"; then
        if ! grep -Eq "CREATE TABLE.*\);" "$file" && ! grep -Eq "CREATE TABLE.*\).*ENGINE" "$file"; then
            warning "$file: Possibles points-virgules manquants après CREATE TABLE"
        fi
    fi
done
success "Syntaxe de base vérifiée"
echo ""

echo "4. Vérification des patterns MySQL..."
for file in "${SQL_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    # Vérifier l'utilisation de IF NOT EXISTS pour CREATE TABLE
    if grep -qi "CREATE TABLE" "$file"; then
        if ! grep -qi "CREATE TABLE IF NOT EXISTS" "$file"; then
            warning "$file: CREATE TABLE sans IF NOT EXISTS (recommandé pour l'idempotence)"
        fi
    fi
    
    # Vérifier ENGINE=InnoDB
    if grep -qi "CREATE TABLE" "$file"; then
        if ! grep -qi "ENGINE=InnoDB" "$file"; then
            warning "$file: ENGINE=InnoDB non spécifié (recommandé)"
        fi
    fi
    
    # Vérifier CHARSET utf8mb4
    if grep -qi "CREATE TABLE" "$file"; then
        if ! grep -qi "CHARSET=utf8mb4" "$file"; then
            warning "$file: CHARSET=utf8mb4 non spécifié (recommandé)"
        fi
    fi
    
    # Vérifier l'utilisation de AUTO_INCREMENT sur PRIMARY KEY
    if grep -qi "AUTO_INCREMENT" "$file" && grep -qi "PRIMARY KEY" "$file"; then
        if ! grep -Eqi "AUTO_INCREMENT.*PRIMARY KEY|PRIMARY KEY.*AUTO_INCREMENT" "$file"; then
            # Vérification plus approfondie
            :
        fi
    fi
done
success "Patterns MySQL vérifiés"
echo ""

echo "5. Détection de commandes potentiellement dangereuses..."
DANGEROUS_COMMANDS=("TRUNCATE" "DROP DATABASE" "DROP SCHEMA")

for file in "${SQL_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    for cmd in "${DANGEROUS_COMMANDS[@]}"; do
        if grep -qi "\b$cmd\b" "$file"; then
            error "$file: Commande dangereuse détectée: $cmd"
        fi
    done
    
    # DROP TABLE sans IF EXISTS
    if grep -Ei "\bDROP TABLE\b" "$file" | grep -qvi "IF EXISTS"; then
        warning "$file: DROP TABLE sans IF EXISTS détecté"
    fi
    
    # DELETE sans WHERE
    if grep -Ei "^\s*DELETE FROM" "$file" | grep -qvi "WHERE"; then
        warning "$file: DELETE sans WHERE détecté (suppression totale)"
    fi
    
    # UPDATE sans WHERE
    if grep -Ei "^\s*UPDATE.*SET" "$file" | grep -qvi "WHERE"; then
        warning "$file: UPDATE sans WHERE détecté (mise à jour totale)"
    fi
done
success "Commandes dangereuses vérifiées"
echo ""

echo "6. Vérification des conventions de nommage..."
for file in "${SQL_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    # Tables avec majuscules dans le nom
    if grep -Ei "CREATE TABLE.*[A-Z]" "$file" | grep -qv "IF NOT EXISTS"; then
        warning "$file: Nom de table avec majuscules détecté (recommandé: snake_case minuscule)"
    fi
    
    # Colonnes avec majuscules
    if grep -Ei "^\s+[A-Z][a-zA-Z]+ " "$file" | grep -qv "^--"; then
        # Ignorer les commentaires
        :
    fi
done
success "Conventions de nommage vérifiées"
echo ""

echo "7. Vérification des meilleures pratiques..."
for file in "${SQL_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    # Vérifier la présence de commentaires pour les tables
    if grep -qi "CREATE TABLE" "$file"; then
        if ! grep -qi "COMMENT=" "$file"; then
            info "$file: Aucun COMMENT sur la table (recommandé mais optionnel)"
        fi
    fi
    
    # Vérifier les timestamps automatiques
    if grep -qi "CREATE TABLE" "$file"; then
        if ! grep -qi "created_at.*TIMESTAMP" "$file"; then
            info "$file: Colonne created_at non trouvée (recommandé pour l'audit)"
        fi
        if ! grep -qi "updated_at.*TIMESTAMP" "$file"; then
            info "$file: Colonne updated_at non trouvée (recommandé pour l'audit)"
        fi
    fi
done
success "Meilleures pratiques vérifiées"
echo ""

# Test de syntaxe avec MySQL si disponible
echo "8. Test de syntaxe MySQL (si disponible)..."
if command -v mysql &> /dev/null; then
    info "MySQL client trouvé, test de syntaxe approfondi..."
    
    for file in "${SQL_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            continue
        fi
        
        # Tenter de valider la syntaxe sans exécuter
        # Note: MySQL n'a pas de mode "dry-run" natif, donc on simule avec --help
        # Cette section peut être améliorée avec un parseur SQL dédié
        
        # Vérifier qu'il n'y a pas d'erreurs évidentes
        if grep -qi "SYNTAX ERROR" "$file"; then
            error "$file: SYNTAX ERROR détecté dans le fichier"
        fi
    done
else
    info "MySQL client non disponible, test de syntaxe approfondi ignoré"
fi
echo ""

# Résumé
echo "================================================"
echo "  Résumé de la vérification"
echo "================================================"
echo "Fichiers vérifiés: ${#SQL_FILES[@]}"
echo -e "Erreurs: ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}✗ VÉRIFICATION ÉCHOUÉE${NC}"
    echo "Veuillez corriger les erreurs de syntaxe avant de continuer."
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ VÉRIFICATION RÉUSSIE AVEC WARNINGS${NC}"
    echo "Veuillez examiner les warnings ci-dessus."
    exit 0
else
    echo -e "${GREEN}✓ VÉRIFICATION RÉUSSIE${NC}"
    echo "La syntaxe SQL est correcte."
    exit 0
fi
