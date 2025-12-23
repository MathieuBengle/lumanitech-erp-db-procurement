#!/usr/bin/env bash
# deploy.sh
# Orchestrates schema, migrations, and optional seed deployment for Procurement.
set -euo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCHEMA_DIR="$PROJECT_ROOT/schema"
APPLY_SCRIPT="$SCRIPT_DIR/apply-migrations.sh"

# Defaults
DB_HOST="localhost"
DB_PORT="3306"
DB_NAME="lumanitech_erp_procurement"
DB_USER="admin"
LOGIN_PATH="local"
WITH_SEEDS=false
SEED_DIRS=("$PROJECT_ROOT/seeds/dev")

MYSQL_CMD=()

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

usage() {
  cat <<'EOF'
Usage: deploy.sh [OPTIONS]

Options:
  -h, --host HOST           MySQL host (default: localhost)
  -P, --port PORT           MySQL port (default: 3306)
  -d, --database NAME       Target database (default: lumanitech_erp_procurement)
  -u, --user USER           MySQL user (default: admin)
  --login-path=NAME         mysql_config_editor login path (default: local)
  --with-seeds             Load seeds/reference and seeds/sample
  --help                   Show this help message
EOF
  exit 1
}

prompt_password() {
  read -s -p "Mot de passe pour '$DB_USER'@'$DB_HOST': " DB_PASSWORD
  echo
}

ensure_mysql_client() {
  if ! command -v mysql &> /dev/null; then
    error "mysql client introuvable"
    exit 1
  fi
}

verify_login_path() {
  if ! command -v mysql_config_editor &> /dev/null; then
    error "mysql_config_editor introuvable"
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

  # Fallback: rely on mysql's own interactive password prompt to avoid exposing
  # the password via command-line arguments.
  MYSQL_CMD=(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p)
}

mysql_exec() {
  "${MYSQL_CMD[@]}" "$@"
}

mysql_exec_db() {
  "${MYSQL_CMD[@]}" "$DB_NAME" "$@"
}

run_sql_dir() {
  local label=$1
  local dir=$2

  if [ ! -d "$dir" ]; then
    warn "Pas de $label (dossier manquant: $dir)"
    return
  fi

  local files=("$dir"/*.sql)
  if [ ${#files[@]} -eq 0 ]; then
    warn "Aucun fichier SQL dans $dir"
    return
  fi

  IFS=$'\n' sorted=($(printf '%s\n' "${files[@]}" | sort))
  unset IFS

  for path in "${sorted[@]}"; do
    info "Exécution $label: $(basename "$path")"
    mysql_exec_db < "$path"
  done
}

ensure_database() {
  info "Création si besoin de la base '$DB_NAME'"
  mysql_exec -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

apply_migrations() {
  info "Application des migrations"
  local args=("--host" "$DB_HOST" "--port" "$DB_PORT" "--database" "$DB_NAME" "--user" "$DB_USER")
  if [ -n "$LOGIN_PATH" ]; then
    args+=("--login-path=$LOGIN_PATH")
  fi
  bash "$APPLY_SCRIPT" "${args[@]}"
}

load_seeds() {
  if [ "$WITH_SEEDS" != true ]; then
    return
  fi
  info "Chargement des seeds"
  for seed_dir in "${SEED_DIRS[@]}"; do
    if [ ! -d "$seed_dir" ]; then
      warn "Seed dir manquant: $seed_dir"
      continue
    fi
    run_sql_dir "seed" "$seed_dir"
  done
}

# Analyse des options
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
    --login-path=*)
      LOGIN_PATH="${1#*=}"
      shift
      ;;
    --with-seeds)
      WITH_SEEDS=true
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

info "Déploiement Procurement DB"
info "  Database: $DB_NAME"
info "  Host:     $DB_HOST:$DB_PORT"
info "  Login path: ${LOGIN_PATH:-(interactive)}"
info "  Chargement des seeds: $WITH_SEEDS"

ensure_mysql_client
build_mysql_cmd
info "Vérification connexion"
mysql_exec -e "SELECT 1" &> /dev/null
success "Connexion valide"

ensure_database
run_sql_dir "tables" "$SCHEMA_DIR/tables"
run_sql_dir "views" "$SCHEMA_DIR/views"
run_sql_dir "procedures" "$SCHEMA_DIR/procedures"
run_sql_dir "functions" "$SCHEMA_DIR/functions"
run_sql_dir "triggers" "$SCHEMA_DIR/triggers"
run_sql_dir "indexes" "$SCHEMA_DIR/indexes"
apply_migrations
load_seeds
success "Déploiement $DB_NAME DB terminé"
