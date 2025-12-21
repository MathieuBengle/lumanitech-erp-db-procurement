#!/bin/bash

# apply-migrations.sh
# Script d'application des migrations pour la base de données Procurement
# Applique les migrations dans l'ordre séquentiel

set -e

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables par défaut
DB_HOST="localhost"
DB_PORT="3306"
DB_NAME="procurement"
DB_USER="root"
DB_PASSWORD=""
MIGRATIONS_DIR="migrations"
DRY_RUN=false
FORCE=false

# Fonction pour afficher l'usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -h, --host HOST        Hôte de la base de données (défaut: localhost)
    -P, --port PORT        Port de la base de données (défaut: 3306)
    -d, --database DB      Nom de la base de données (défaut: procurement)
    -u, --user USER        Utilisateur MySQL (défaut: root)
    -p, --password PASS    Mot de passe MySQL
    -n, --dry-run          Mode simulation (n'applique pas les migrations)
    -f, --force            Force l'application même si déjà appliquée
    --help                 Affiche cette aide

Exemples:
    $0 -u root -p mypassword
    $0 --database procurement --dry-run
    $0 -h db.example.com -u admin -p secret
EOF
    exit 1
}

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            DB_HOST="$2"
            shift 2
            ;;
        -P|--port)
            DB_PORT="$2"
            shift 2
            ;;
        -d|--database)
            DB_NAME="$2"
            shift 2
            ;;
        -u|--user)
            DB_USER="$2"
            shift 2
            ;;
        -p|--password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo "Option inconnue: $1"
            usage
            ;;
    esac
done

# Fonctions utilitaires
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Construire la commande MySQL
MYSQL_CMD="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
if [ -n "$DB_PASSWORD" ]; then
    MYSQL_CMD="$MYSQL_CMD -p$DB_PASSWORD"
fi

echo "================================================"
echo "  Application des migrations - Procurement DB"
echo "================================================"
echo ""
info "Configuration:"
echo "  Hôte:        $DB_HOST:$DB_PORT"
echo "  Base:        $DB_NAME"
echo "  Utilisateur: $DB_USER"
echo "  Mode:        $([ "$DRY_RUN" = true ] && echo "DRY-RUN (simulation)" || echo "PRODUCTION")"
echo ""

# Vérifier la connexion à la base de données
info "Vérification de la connexion à la base de données..."
if ! $MYSQL_CMD -e "SELECT 1" &> /dev/null; then
    error "Impossible de se connecter à la base de données"
    echo "Vérifiez vos paramètres de connexion."
    exit 1
fi
success "Connexion réussie"
echo ""

# Vérifier que la base de données existe
info "Vérification de l'existence de la base '$DB_NAME'..."
if ! $MYSQL_CMD -e "USE $DB_NAME" &> /dev/null; then
    error "La base de données '$DB_NAME' n'existe pas"
    echo "Créez-la avec: CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    exit 1
fi
success "Base de données trouvée"
echo ""

# Créer la table de suivi des migrations si elle n'existe pas
info "Vérification de la table schema_migrations..."
$MYSQL_CMD $DB_NAME << 'EOF'
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(50) PRIMARY KEY,
    description VARCHAR(255),
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_applied_at (applied_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
EOF
success "Table schema_migrations prête"
echo ""

# Récupérer les migrations déjà appliquées
info "Récupération des migrations déjà appliquées..."
APPLIED_MIGRATIONS=$($MYSQL_CMD $DB_NAME -N -e "SELECT version FROM schema_migrations ORDER BY version")
APPLIED_COUNT=$(echo "$APPLIED_MIGRATIONS" | grep -c "^V" || true)
info "$APPLIED_COUNT migration(s) déjà appliquée(s)"
echo ""

# Vérifier que le dossier migrations existe
if [ ! -d "$MIGRATIONS_DIR" ]; then
    error "Le dossier '$MIGRATIONS_DIR' n'existe pas"
    exit 1
fi

cd "$MIGRATIONS_DIR"

# Lister les fichiers de migration
MIGRATION_FILES=(V*.sql)
if [ ${#MIGRATION_FILES[@]} -eq 0 ] || [ ! -f "${MIGRATION_FILES[0]}" ]; then
    warning "Aucune migration trouvée dans $MIGRATIONS_DIR"
    exit 0
fi

info "Trouvé ${#MIGRATION_FILES[@]} migration(s) dans $MIGRATIONS_DIR"
echo ""

# Appliquer les migrations
APPLIED=0
SKIPPED=0
FAILED=0

echo "================================================"
echo "  Application des migrations"
echo "================================================"
echo ""

for file in "${MIGRATION_FILES[@]}"; do
    # Extraire le numéro de version
    if [[ "$file" =~ ^V([0-9]{3})_(.+)\.sql$ ]]; then
        VERSION="V${BASH_REMATCH[1]}"
        DESCRIPTION="${BASH_REMATCH[2]}"
        
        # Vérifier si déjà appliquée
        if echo "$APPLIED_MIGRATIONS" | grep -q "^$VERSION$"; then
            if [ "$FORCE" = false ]; then
                info "[$VERSION] Déjà appliquée - ignorée"
                ((SKIPPED++))
                continue
            else
                warning "[$VERSION] Déjà appliquée mais force activé - réapplication"
            fi
        fi
        
        # Afficher la migration en cours
        echo -e "${BLUE}▶${NC} [$VERSION] $DESCRIPTION"
        
        if [ "$DRY_RUN" = true ]; then
            info "  Mode dry-run - simulation uniquement"
            success "  Migration simulée"
            ((APPLIED++))
        else
            # Appliquer la migration
            if $MYSQL_CMD $DB_NAME < "$file" 2>&1; then
                success "  Migration appliquée avec succès"
                ((APPLIED++))
            else
                error "  Échec de la migration"
                ((FAILED++))
                echo ""
                error "L'application des migrations a échoué sur $file"
                echo "Vérifiez les erreurs ci-dessus et corrigez le problème."
                exit 1
            fi
        fi
        echo ""
    else
        warning "Fichier ignoré (nomenclature incorrecte): $file"
    fi
done

# Résumé
echo "================================================"
echo "  Résumé"
echo "================================================"
echo "Migrations trouvées:       ${#MIGRATION_FILES[@]}"
echo "Migrations appliquées:     $APPLIED"
echo "Migrations ignorées:       $SKIPPED"
echo "Migrations échouées:       $FAILED"
echo ""

if [ "$DRY_RUN" = true ]; then
    warning "Mode DRY-RUN - Aucune modification n'a été faite"
    echo "Relancez sans --dry-run pour appliquer réellement les migrations."
elif [ $APPLIED -gt 0 ]; then
    success "Toutes les migrations ont été appliquées avec succès!"
elif [ $SKIPPED -gt 0 ]; then
    info "Toutes les migrations étaient déjà appliquées."
else
    info "Aucune migration à appliquer."
fi

exit 0
