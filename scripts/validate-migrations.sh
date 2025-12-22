#!/bin/bash

# validate-migrations.sh
# Script de validation des migrations pour la base de données Procurement
# Vérifie la nomenclature, la séquence et l'intégrité des migrations

set -e

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
MIGRATIONS_DIR="migrations"
ERRORS=0
WARNINGS=0

echo "================================================"
echo "  Validation des migrations - Procurement DB"
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

cd "$MIGRATIONS_DIR"

echo "1. Vérification de la présence de fichiers de migration..."
MIGRATION_FILES=(V*.sql)

if [ ${#MIGRATION_FILES[@]} -eq 0 ] || [ ! -f "${MIGRATION_FILES[0]}" ]; then
    warning "Aucun fichier de migration trouvé (V*.sql)"
    echo ""
    echo "Résumé: 0 fichiers validés"
    exit 0
fi

success "Trouvé ${#MIGRATION_FILES[@]} fichier(s) de migration"
echo ""

echo "2. Vérification de la nomenclature des fichiers..."
NOMENCLATURE_PATTERN="^V[0-9]{3}_[a-z0-9_]+\.sql$"

for file in "${MIGRATION_FILES[@]}"; do
    if [[ ! "$file" =~ $NOMENCLATURE_PATTERN ]]; then
        error "Nomenclature invalide: $file (attendu: VXXX_description.sql)"
    else
        success "Nomenclature correcte: $file"
    fi
done
echo ""

echo "3. Vérification de la séquence numérique..."
declare -A seen_numbers
LAST_NUMBER=-1

for file in "${MIGRATION_FILES[@]}"; do
    # Extraire le numéro de version (ex: V001 -> 001)
    if [[ "$file" =~ ^V([0-9]{3}) ]]; then
        NUMBER="${BASH_REMATCH[1]}"
        NUMBER_INT=$((10#$NUMBER))  # Convertir en entier (enlever les zéros de tête)
        
        # Vérifier les doublons
        if [ -n "${seen_numbers[$NUMBER]}" ]; then
            error "Numéro dupliqué V$NUMBER: ${seen_numbers[$NUMBER]} et $file"
        else
            seen_numbers[$NUMBER]="$file"
        fi
        
        # Vérifier la séquence
        if [ $LAST_NUMBER -ge 0 ]; then
            EXPECTED=$((LAST_NUMBER + 1))
            if [ $NUMBER_INT -ne $EXPECTED ]; then
                if [ $NUMBER_INT -gt $EXPECTED ]; then
                    warning "Trou dans la séquence: V$(printf "%03d" $EXPECTED) manquant avant $file"
                else
                    error "Séquence incorrecte: $file après V$(printf "%03d" $LAST_NUMBER)"
                fi
            fi
        fi
        
        LAST_NUMBER=$NUMBER_INT
    fi
done

if [ $ERRORS -eq 0 ]; then
    success "Séquence numérique valide (V001 à V$(printf "%03d" $LAST_NUMBER))"
fi
echo ""

echo "4. Vérification des fichiers interdits (rollback)..."
FORBIDDEN_PATTERNS=("*_down.sql" "*_rollback.sql" "*_revert.sql" "*_undo.sql")
FORBIDDEN_FOUND=0

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    for file in $pattern; do
        if [ -f "$file" ]; then
            error "Fichier de rollback interdit trouvé: $file (stratégie forward-only)"
            ((FORBIDDEN_FOUND++))
        fi
    done
done

if [ $FORBIDDEN_FOUND -eq 0 ]; then
    success "Aucun fichier de rollback trouvé (forward-only confirmé)"
fi
echo ""

echo "5. Vérification du contenu des migrations..."
for file in "${MIGRATION_FILES[@]}"; do
    # Vérifier la présence d'un header
    if ! grep -q "^-- Migration:" "$file"; then
        warning "$file: Header 'Migration:' manquant"
    fi
    
    # Vérifier la présence de START TRANSACTION
    if ! grep -qi "START TRANSACTION" "$file"; then
        warning "$file: 'START TRANSACTION' manquant (recommandé)"
    fi
    
    # Vérifier la présence de COMMIT
    if ! grep -qi "COMMIT" "$file"; then
        warning "$file: 'COMMIT' manquant (recommandé)"
    fi
    
    # Vérifier les commandes dangereuses sans IF EXISTS
    if grep -qi "DROP TABLE" "$file" && ! grep -qi "DROP TABLE IF EXISTS" "$file"; then
        warning "$file: 'DROP TABLE' sans 'IF EXISTS' détecté (risqué)"
    fi
    
    if grep -qi "DROP COLUMN" "$file"; then
        warning "$file: 'DROP COLUMN' détecté (migration destructive)"
    fi
done

success "Vérification du contenu terminée"
echo ""

echo "6. Vérification des permissions des fichiers..."
for file in "${MIGRATION_FILES[@]}"; do
    if [ ! -r "$file" ]; then
        error "$file: Fichier non lisible"
    fi
done
success "Permissions correctes"
echo ""

# Résumé
echo "================================================"
echo "  Résumé de la validation"
echo "================================================"
echo "Fichiers vérifiés: ${#MIGRATION_FILES[@]}"
echo -e "Erreurs: ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}✗ VALIDATION ÉCHOUÉE${NC}"
    echo "Veuillez corriger les erreurs ci-dessus avant de continuer."
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ VALIDATION RÉUSSIE AVEC WARNINGS${NC}"
    echo "Veuillez vérifier les warnings ci-dessus."
    exit 0
else
    echo -e "${GREEN}✓ VALIDATION RÉUSSIE${NC}"
    echo "Toutes les vérifications sont passées avec succès."
    exit 0
fi
