#!/bin/bash

# ============================================================================
# DB Utilities - Common functions for database operations
# ============================================================================

set -e

# ============================================================================
# Color Codes
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Logging Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# ============================================================================
# DATABASE_URL Parsing Function
# ============================================================================

# Parse DATABASE_URL and extract components
# Usage: parse_database_url "postgresql://user:pass@localhost:5433/dbname"
# Sets: DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME
parse_database_url() {
    local url="$1"

    # Regex to parse: postgresql://user:pass@host:port/dbname
    if [[ $url =~ ^postgresql://([^:]+):([^@]+)@([^:]+):([0-9]+)/(.+)$ ]]; then
        DB_USER="${BASH_REMATCH[1]}"
        DB_PASS="${BASH_REMATCH[2]}"
        DB_HOST="${BASH_REMATCH[3]}"
        DB_PORT="${BASH_REMATCH[4]}"
        DB_NAME="${BASH_REMATCH[5]}"
        return 0
    else
        log_error "Invalid DATABASE_URL format: $url"
        log_info "Expected format: postgresql://user:pass@host:port/dbname"
        return 1
    fi
}

# ============================================================================
# PostgreSQL Tools Check
# ============================================================================

check_postgresql_tools() {
    local PG_BIN_DIR="/opt/homebrew/opt/postgresql@16/bin"

    # Check if PostgreSQL bin directory exists
    if [ ! -d "$PG_BIN_DIR" ]; then
        log_error "PostgreSQL@16 bin directory not found: $PG_BIN_DIR"
        log_info "Please install PostgreSQL@16:"
        log_info "  brew install postgresql@16"
        return 1
    fi

    # Check for required tools
    local required_tools=("pg_dump" "pg_restore" "pg_isready" "psql")

    for tool in "${required_tools[@]}"; do
        if [ ! -x "$PG_BIN_DIR/$tool" ]; then
            log_error "Required tool not found: $tool"
            log_info "Please reinstall PostgreSQL@16"
            return 1
        fi
    done

    # Export PATH
    export PATH="$PG_BIN_DIR:$PATH"
    log_success "PostgreSQL tools available"
    return 0
}

# ============================================================================
# Docker Check
# ============================================================================

check_docker() {
    # Check if docker command exists
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found"
        log_info "Please install Docker Desktop"
        return 1
    fi

    # Check if docker-compose command exists
    if ! command -v docker-compose &> /dev/null; then
        log_error "docker-compose not found"
        log_info "Please install docker-compose"
        return 1
    fi

    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        log_info "Please start Docker Desktop"
        return 1
    fi

    log_success "Docker is available and running"
    return 0
}

# ============================================================================
# Prisma CLI Check
# ============================================================================

check_prisma() {
    # Check if npx command exists
    if ! command -v npx &> /dev/null; then
        log_error "npx not found"
        log_info "Please install Node.js and npm"
        return 1
    fi

    # Check if prisma is executable via npx
    if ! npx prisma --version &> /dev/null; then
        log_error "Prisma CLI not accessible via npx"
        log_info "Please install Prisma:"
        log_info "  npm install -D prisma"
        return 1
    fi

    log_success "Prisma CLI is available"
    return 0
}
