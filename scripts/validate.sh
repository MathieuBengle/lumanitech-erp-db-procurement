#!/usr/bin/env bash
# validate.sh
# Comprehensive validation script for the Procurement database repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

ERRORS=0

echo "================================================"
echo "  Procurement DB - Full Validation Suite"
echo "================================================"
echo ""

# Step 1: Validate migrations
info "Step 1: Validating migrations..."
if bash "$SCRIPT_DIR/validate-migrations.sh"; then
    success "Migration validation passed"
else
    error "Migration validation failed"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Step 2: Validate SQL syntax
info "Step 2: Validating SQL syntax..."
if bash "$SCRIPT_DIR/validate-sql-syntax.sh"; then
    success "SQL syntax validation passed"
else
    error "SQL syntax validation failed"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Step 3: Validate schema structure
info "Step 3: Validating schema structure..."
schema_dir="$PROJECT_ROOT/schema"
required_dirs=("tables" "views" "procedures" "functions" "triggers" "indexes")

for dir in "${required_dirs[@]}"; do
    if [[ -d "$schema_dir/$dir" ]]; then
        echo -e "${GREEN}✓${NC} schema/$dir exists"
    else
        echo -e "${RED}✗ schema/$dir missing${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# Step 4: Validate seeds structure
info "Step 4: Validating seeds structure..."
if [[ -d "$PROJECT_ROOT/seeds/dev" ]]; then
    echo -e "${GREEN}✓${NC} seeds/dev exists"
else
    echo -e "${RED}✗ seeds/dev missing${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Step 5: Validate schema file naming
echo -e "${BLUE}Step 5: Validate schema file naming...${NC}"

# Check procedures
check_dir="$schema_dir/procedures"
if [[ -d "$check_dir" ]]; then
    for f in "$check_dir"/*.sql; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f")
        if [[ ! "$name" =~ ^sp_[a-z0-9_]+\.sql$ ]]; then
            echo -e "${RED}✗ Invalid procedure filename: $name (expected sp_name.sql)${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${GREEN}✓${NC} $name"
        fi
    done
fi

# Check triggers
check_dir="$schema_dir/triggers"
if [[ -d "$check_dir" ]]; then
    for f in "$check_dir"/*.sql; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f")
        if [[ ! "$name" =~ ^trg_[a-z0-9_]+\.sql$ ]]; then
            echo -e "${RED}✗ Invalid trigger filename: $name (expected trg_name.sql)${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${GREEN}✓${NC} $name"
        fi
    done
fi

echo ""
echo "================================================"
echo "  Validation Summary"
echo "================================================"
echo "Total Errors: $ERRORS"
echo ""

if [ $ERRORS -eq 0 ]; then
    success "All validation checks passed ✓"
    exit 0
else
    error "Some validation checks failed ✗"
    exit 1
fi
