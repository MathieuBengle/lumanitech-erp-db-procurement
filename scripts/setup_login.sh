#!/usr/bin/env bash
# setup_login.sh
# Configure MySQL login path

set -e

echo "================================================"
echo "  MySQL Login Path Setup"
echo "================================================"
echo ""

# Detect WSL2
is_wsl2() {
    grep -qi microsoft /proc/version 2>/dev/null
}

default_user="root"
if is_wsl2; then
    default_user="admin"
    echo "WSL2 detected. Default user: admin"
fi

echo "This will configure mysql_config_editor for secure credential storage."
echo ""

read -p "Login path name (default: local): " login_path
login_path=${login_path:-local}

read -p "MySQL host (default: localhost): " host
host=${host:-localhost}

read -p "MySQL user (default: $default_user): " user
user=${user:-$default_user}

echo ""
echo "Configuring login path '$login_path'..."
mysql_config_editor set --login-path="$login_path" \
    --host="$host" \
    --user="$user" \
    --password

echo ""
echo "Login path configured successfully!"
echo "You can now use: --login-path=$login_path"
