#!/usr/bin/env bash
# setup.sh
# Initial setup script for Procurement database

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================"
echo "  Procurement Database - Setup"
echo "================================================"
echo ""

# Source common functions if available
if [[ -f "$SCRIPT_DIR/mysql-common.sh" ]]; then
    source "$SCRIPT_DIR/mysql-common.sh"
fi

echo "This script will help you set up the Procurement database."
echo ""
echo "Steps:"
echo "1. Configure MySQL credentials (optional)"
echo "2. Create database"
echo "3. Deploy schema and migrations"
echo "4. Load seed data (optional)"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Run setup_login.sh if available
if [[ -f "$SCRIPT_DIR/setup_login.sh" ]]; then
    bash "$SCRIPT_DIR/setup_login.sh"
fi

# Run deploy.sh
echo ""
echo "Deploying database..."
bash "$SCRIPT_DIR/deploy.sh" --login-path=local --with-seeds

echo ""
echo "================================================"
echo "  Setup Complete!"
echo "================================================"
