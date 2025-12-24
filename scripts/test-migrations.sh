#!/usr/bin/env bash
# test-migrations.sh
# Test migrations on a temporary database

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${BLUE}[SUCCESS]${NC} $1"; }

echo "================================================"
echo "  Test Migrations"
echo "================================================"
echo ""

LOGIN_PATH="local"
TEST_DB="lumanitech_erp_procurement_test"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --login-path)
            LOGIN_PATH="$2"
            shift 2
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

info "Creating test database: $TEST_DB"
mysql --login-path="$LOGIN_PATH" -e "DROP DATABASE IF EXISTS $TEST_DB"
mysql --login-path="$LOGIN_PATH" -e "CREATE DATABASE $TEST_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"

info "Applying migrations to test database..."
bash "$SCRIPT_DIR/apply-migrations.sh" --login-path="$LOGIN_PATH" --database="$TEST_DB"

success "Migration test completed successfully!"

info "Cleaning up test database..."
mysql --login-path="$LOGIN_PATH" -e "DROP DATABASE $TEST_DB"

echo ""
success "All tests passed!"
