#!/usr/bin/env bash
# apply-migrations.sh
# Applique de manière séquentielle les migrations de la base Procurement.
set -euo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MIGRATIONS_DIR="$PROJECT_ROOT/migrations"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Paramètres par défaut
DB_HOST="localhost"
DB_PORT="3306"
DB_NAME="lumanitech_erp_procurement"
DB_USER="admin"
DB_PASSWORD=""
LOGIN_PATH=""
PROMPT_FOR_PASSWORD=true
DRY_RUN=false
FORCE=false

MYSQL_CMD=()

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

usage() {
  cat <<'EOF'
Usage: apply-migrations.sh [OPTIONS]

Options:
  -h, --host HOST           Hôte MySQL (défaut: localhost)
  -P, --port PORT           Port MySQL (défaut: 3306)
  -d, --database NAME       Base (défaut: lumanitech_erp_procurement)
  -u, --user USER           Utilisateur (défaut: admin)
  -p, --password PASS       Mot de passe (évite de repasser en invite)
  --login-path NAME         mysql_config_editor login path
  --dry-run                 Simuler sans appliquer
  --force                   Réappliquer même si déjà appliquée
  --help                    Afficher cette aide
EOF
  exit 1
}

prompt_password() {
  read -s -p "Entrez le mot de passe MySQL pour '$DB_USER'@'$DB_HOST': " DB_PASSWORD
  echo
}

ensure_mysql_client() {
  if ! command -v mysql &> /dev/null; then
    error "mysql n'est pas installé"
    exit 1
  fi
}

verify_login_path() {
  if ! command -v mysql_config_editor &> /dev/null; then
    error "mysql_config_editor manquant"
    exit 1
  fi
  if ! mysql_config_editor print --login-path="$LOGIN_PATH" &> /dev/null; then
    error "Login path '$LOGIN_PATH' introuvable"
    info "Créez-le avec"
    echo "  mysql_config_editor set --login-path=$LOGIN_PATH --host=$DB_HOST --user=$DB_USER --password"
    exit 1
  fi
  info "Utilisation du login path $LOGIN_PATH"
}

build_mysql_cmd() {
  if [ -n "$LOGIN_PATH" ]; then
    verify_login_path
    MYSQL_CMD=(mysql --login-path="$LOGIN_PATH" -h "$DB_HOST" -P "$DB_PORT")
    return
  fi

  if [ -z "$DB_PASSWORD" ] && [ "$PROMPT_FOR_PASSWORD" = true ]; then
    prompt_password
  fi

  MYSQL_CMD=(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER")
  if [ -n "$DB_PASSWORD" ]; then
    MYSQL_CMD+=("-p$DB_PASSWORD")
  fi
}

mysql_exec() {
  "${MYSQL_CMD[@]}" "$@"
}

mysql_exec_db() {
  "${MYSQL_CMD[@]}" "$DB_NAME" "$@"
}

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
      PROMPT_FOR_PASSWORD=false
      shift 2
      ;;
    -p=*|--password=*)
      DB_PASSWORD="${1#*=}"
      PROMPT_FOR_PASSWORD=false
      shift
      ;;
    --login-path=*)
      LOGIN_PATH="${1#*=}"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --help)
      usage
      ;;
    *)
      error "Option inconnue: $1"
      usage
      ;;
  esac
done

ensure_mysql_client
build_mysql_cmd

info "Configuration"
info "  Hôte:        $DB_HOST:$DB_PORT"
info "  Base:        $DB_NAME"
info "  Utilisateur: $DB_USER"
if [ -n "$LOGIN_PATH" ]; then
  info "  Login path:  $LOGIN_PATH"
else
  info "  Authentification interactive"
fi
info "  Mode:        $([ "$DRY_RUN" = true ] && echo "DRY-RUN" || echo "PRODUCTION")"

echo "================================================"
echo "  Application des migrations"
echo "================================================"

info "Vérification de la connexion..."
if ! mysql_exec -e "SELECT 1" &> /dev/null; then
  error "Impossible de se connecter à MySQL"
  exit 1
fi
success "Connexion établie"

echo
info "Création de schema_migrations si nécessaire"
mysql_exec_db <<'EOF'
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(50) PRIMARY KEY,
    description VARCHAR(255),
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_applied_at (applied_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
EOF
success "Table schema_migrations prête"

echo
info "Récupération des migrations déjà appliquées"
APPLIED_MIGRATIONS=$(mysql_exec_db -N -e "SELECT version FROM schema_migrations ORDER BY version" || true)
APPLIED_COUNT=$(printf '%s\n' "$APPLIED_MIGRATIONS" | grep -c '^V' || true)
info "$APPLIED_COUNT migration(s) déjà appliquée(s)"

echo
if [ ! -d "$MIGRATIONS_DIR" ]; then
  warning "Répertoire migrations introuvable: $MIGRATIONS_DIR"
  exit 1
fi

mapfile -t MIGRATION_FILES < <(cd "$MIGRATIONS_DIR" && printf '%s\n' V*.sql | sort)
if [ ${#MIGRATION_FILES[@]} -eq 0 ]; then
  warning "Aucune migration dans $MIGRATIONS_DIR"
  exit 0
fi
if [ ! -f "$MIGRATIONS_DIR/${MIGRATION_FILES[0]}" ]; then
  warning "Fichier de migration introuvable: ${MIGRATION_FILES[0]}"
  exit 1
fi

info "${#MIGRATION_FILES[@]} migration(s) détectée(s)"

echo ""
APPLIED=0
SKIPPED=0
FAILED=0

for file in "${MIGRATION_FILES[@]}"; do
  if [[ "$file" =~ ^V([0-9]{3})_(.+)\.sql$ ]]; then
    VERSION="V${BASH_REMATCH[1]}"
    DESCRIPTION="${BASH_REMATCH[2]}"
    if printf '%s\n' "$APPLIED_MIGRATIONS" | grep -qx "$VERSION"; then
      if [ "$FORCE" = false ]; then
        info "[$VERSION] déjà appliquée"
        ((SKIPPED++))
        continue
      else
        warning "[$VERSION] déjà appliquée, réapplication demandée"
      fi
    fi

    echo -e "${BLUE}▶${NC} [$VERSION] $DESCRIPTION"
    if [ "$DRY_RUN" = true ]; then
      info "  Simulation uniquement"
      ((APPLIED++))
    else
      if mysql_exec_db < "$MIGRATIONS_DIR/$file" 2>&1; then
        success "  Migration appliquée"
        ((APPLIED++))
      else
        error "  Échec de la migration"
        ((FAILED++))
        echo
        error "Application interrompue sur $file"
        exit 1
      fi
    fi
    echo
  else
    warning "Fichier ignoré (nomenclature incorrecte): $file"
  fi
done

echo "================================================"
echo "  Résumé"
echo "================================================"
echo "Migrations détectées:   ${#MIGRATION_FILES[@]}"
echo "Migrations appliquées:  $APPLIED"
echo "Migrations ignorées:    $SKIPPED"
echo "Migrations échouées:    $FAILED"
echo
if [ "$DRY_RUN" = true ]; then
  warning "Mode DRY-RUN - aucune modification"
  exit 0
elif [ $FAILED -gt 0 ]; then
  error "Certaines migrations ont échoué"
  exit 1
elif [ $APPLIED -eq 0 ] && [ $SKIPPED -gt 0 ]; then
  info "Aucune nouvelle migration à appliquer"
else
  success "Toutes les migrations ont été appliquées"
fi

exit 0
