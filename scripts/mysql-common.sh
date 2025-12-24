#!/usr/bin/env bash
# mysql-common.sh
# Common MySQL connection and utility functions for database scripts

# Global variables
DB_HOST=""
DB_PORT="3306"
DB_USER=""
DB_PASSWORD=""
DB_NAME=""
LOGIN_PATH=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect if running in WSL2
is_wsl2() {
    grep -qi microsoft /proc/version 2>/dev/null
}

# Print colored messages
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }

# Parse MySQL connection arguments
parse_mysql_args() {
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
            -u|--user)
                DB_USER="$2"
                shift 2
                ;;
            -p|--password)
                DB_PASSWORD="$2"
                shift 2
                ;;
            -d|--database)
                DB_NAME="$2"
                shift 2
                ;;
            --login-path)
                LOGIN_PATH="$2"
                shift 2
                ;;
            *)
                error "Unknown option: $1"
                return 1
                ;;
        esac
    done
    
    # Set defaults
    DB_HOST="${DB_HOST:-localhost}"
    if [[ -z "$DB_USER" ]]; then
        if is_wsl2; then
            DB_USER="admin"
        else
            DB_USER="root"
        fi
    fi
    
    return 0
}

# Print MySQL help
print_mysql_help() {
    local default_user="root"
    if is_wsl2; then
        default_user="admin"
    fi
    
    cat << HELP
MySQL Connection Options:
  -h, --host HOST          MySQL host (default: localhost)
  -P, --port PORT          MySQL port (default: 3306)
  -u, --user USER          MySQL user (default: $default_user)
  -p, --password PASS      MySQL password
  -d, --database DB        Database name
  --login-path PATH        Use mysql_config_editor login path

Examples:
  # Using login-path (recommended)
  $0 --login-path=local --database=mydb
  
  # Using credentials
  $0 --host=localhost --user=$default_user --password=secret --database=mydb
  
  # WSL2 users: Configure login-path with user 'admin'
  mysql_config_editor set --login-path=local --host=localhost --user=admin --password
HELP
}

# Build MySQL command
build_mysql_cmd() {
    local cmd_args=()
    
    if [[ -n "$LOGIN_PATH" ]]; then
        cmd_args+=("--login-path=$LOGIN_PATH")
    else
        cmd_args+=("-h" "$DB_HOST")
        cmd_args+=("-P" "$DB_PORT")
        cmd_args+=("-u" "$DB_USER")
        if [[ -n "$DB_PASSWORD" ]]; then
            cmd_args+=("-p$DB_PASSWORD")
        fi
    fi
    
    echo "${cmd_args[@]}"
}

# Execute MySQL command
exec_mysql() {
    local mysql_args
    mysql_args=$(build_mysql_cmd)
    
    if [[ -n "$DB_NAME" ]]; then
        mysql $mysql_args "$DB_NAME" "$@"
    else
        mysql $mysql_args "$@"
    fi
}

# Test MySQL connection
test_mysql_connection() {
    if exec_mysql -e "SELECT 1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}
