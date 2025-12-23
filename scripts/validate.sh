#!/usr/bin/env bash
# validate.sh
# Wrapper script that runs all validation checks for the Procurement database repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

echo "================================================"
echo "  Procurement DB - Full Validation Suite"
echo "================================================"
echo ""

EXIT_CODE=0

# Run migration validation
info "Running migration validation..."
if bash "$SCRIPT_DIR/validate-migrations.sh"; then
    success "Migration validation passed"
else
    error "Migration validation failed"
    EXIT_CODE=1
fi

echo ""

# Run syntax check
info "Running SQL syntax check..."
if bash "$SCRIPT_DIR/check-syntax.sh"; then
    success "Syntax check passed"
else
    error "Syntax check failed"
    EXIT_CODE=1
fi

echo ""
echo "================================================"
echo "  Validation Summary"
echo "================================================"

if [ $EXIT_CODE -eq 0 ]; then
    success "All validation checks passed ✓"
else
    error "Some validation checks failed ✗"
fi

exit $EXIT_CODE
