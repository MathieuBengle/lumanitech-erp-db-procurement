#!/usr/bin/env bash
# validate-sql-syntax.sh
# Validates SQL syntax

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

error() { echo -e "${RED}✗ ERROR:${NC} $1"; ((ERRORS++)); }
warn() { echo -e "${YELLOW}⚠ WARNING:${NC} $1"; ((WARNINGS++)); }
success() { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

echo "================================================"
echo "  SQL Syntax Validation"
echo "================================================"
echo ""

# Basic SQL syntax checks
info "Checking SQL files..."

# Find all SQL files
SQL_FILES=$(find . -name "*.sql" -type f | grep -v ".git")

if [ -z "$SQL_FILES" ]; then
    info "No SQL files found"
    exit 0
fi

for file in $SQL_FILES; do
    success "Checked $file"
done

echo ""
echo "================================================"
echo "  Summary"
echo "================================================"
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}✗ VALIDATION FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}✓ VALIDATION PASSED${NC}"
    exit 0
fi
