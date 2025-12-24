#!/usr/bin/env bash
# load-seeds.sh
# Load seed data into the database

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "================================================"
echo "  Load Seed Data"
echo "================================================"
echo ""

LOGIN_PATH="local"
DB_NAME="lumanitech_erp_procurement"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --login-path)
            LOGIN_PATH="$2"
            shift 2
            ;;
        --database)
            DB_NAME="$2"
            shift 2
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

SEEDS_DIR="$PROJECT_ROOT/seeds/dev"

if [[ ! -d "$SEEDS_DIR" ]]; then
    error "Seeds directory not found: $SEEDS_DIR"
    exit 1
fi

info "Loading seeds from $SEEDS_DIR..."

for seed_file in "$SEEDS_DIR"/*.sql; do
    [[ -f "$seed_file" ]] || continue
    info "Loading $(basename "$seed_file")..."
    mysql --login-path="$LOGIN_PATH" "$DB_NAME" < "$seed_file"
done

echo ""
info "All seeds loaded successfully!"
