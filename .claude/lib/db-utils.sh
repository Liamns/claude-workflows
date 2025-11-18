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
# Config File Loading
# ============================================================================

# Load configuration from db-tools.yaml
load_db_config() {
    local config_file=".claude/config/db-tools.yaml"

    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        return 0  # Config file is optional
    fi

    # Simple YAML parser using grep/sed (no external dependencies)
    # Extract postgresql.bin_dir
    if [ -z "$PG_BIN_DIR" ]; then
        PG_BIN_DIR=$(grep -A 20 "^postgresql:" "$config_file" | \
                     grep "bin_dir:" | \
                     sed 's/^[[:space:]]*bin_dir:[[:space:]]*"\([^"]*\)".*/\1/' | \
                     head -1)
    fi

    # Extract docker.command
    if [ -z "$DOCKER_COMMAND" ]; then
        DOCKER_COMMAND=$(grep -A 10 "^docker:" "$config_file" | \
                         grep "command:" | \
                         sed 's/^[[:space:]]*command:[[:space:]]*"\([^"]*\)".*/\1/' | \
                         head -1)
        DOCKER_COMMAND=${DOCKER_COMMAND:-docker}
    fi

    # Extract docker.compose_command
    if [ -z "$COMPOSE_COMMAND" ]; then
        COMPOSE_COMMAND=$(grep -A 10 "^docker:" "$config_file" | \
                          grep "compose_command:" | \
                          sed 's/^[[:space:]]*compose_command:[[:space:]]*"\([^"]*\)".*/\1/' | \
                          head -1)
        COMPOSE_COMMAND=${COMPOSE_COMMAND:-docker-compose}
    fi

    # Extract prisma.command
    if [ -z "$PRISMA_COMMAND" ]; then
        PRISMA_COMMAND=$(grep -A 10 "^prisma:" "$config_file" | \
                         grep "command:" | \
                         sed 's/^[[:space:]]*command:[[:space:]]*"\([^"]*\)".*/\1/' | \
                         head -1)
        PRISMA_COMMAND=${PRISMA_COMMAND:-npx prisma}
    fi
}

# ============================================================================
# DATABASE_URL Parsing Function
# ============================================================================

# Parse DATABASE_URL and extract components
# Usage: parse_database_url "postgresql://user:pass@localhost:5433/dbname"
# Sets: DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME (used by caller)
parse_database_url() {
    local url="$1"

    # Regex to parse: postgresql://user:pass@host:port/dbname
    if [[ $url =~ ^postgresql://([^:]+):([^@]+)@([^:]+):([0-9]+)/(.+)$ ]]; then
        # shellcheck disable=SC2034  # Variables are used by caller script
        DB_USER="${BASH_REMATCH[1]}"
        # shellcheck disable=SC2034
        DB_PASS="${BASH_REMATCH[2]}"
        # shellcheck disable=SC2034
        DB_HOST="${BASH_REMATCH[3]}"
        # shellcheck disable=SC2034
        DB_PORT="${BASH_REMATCH[4]}"
        # shellcheck disable=SC2034
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
    # Load config if not already loaded
    load_db_config

    # Priority 1: Environment variable
    if [ -n "$PG_BIN_DIR" ] && [ -d "$PG_BIN_DIR" ]; then
        export PATH="$PG_BIN_DIR:$PATH"
        log_success "Using PostgreSQL from: $PG_BIN_DIR"
        return 0
    fi

    # Priority 2: Check if tools are already in PATH
    if command -v pg_dump &> /dev/null && \
       command -v pg_restore &> /dev/null && \
       command -v pg_isready &> /dev/null && \
       command -v psql &> /dev/null; then
        log_success "PostgreSQL tools found in PATH"
        return 0
    fi

    # Priority 3: Try common installation paths
    local common_paths=(
        "/opt/homebrew/opt/postgresql@16/bin"  # Apple Silicon Mac
        "/usr/local/opt/postgresql@16/bin"     # Intel Mac
        "/opt/homebrew/opt/postgresql/bin"     # Generic Homebrew
        "/usr/local/pgsql/bin"                 # Generic Linux
        "/usr/lib/postgresql/16/bin"           # Debian/Ubuntu
        "/usr/pgsql-16/bin"                    # RedHat/CentOS
    )

    for path in "${common_paths[@]}"; do
        if [ -d "$path" ]; then
            # Verify required tools exist
            if [ -x "$path/pg_dump" ] && \
               [ -x "$path/pg_restore" ] && \
               [ -x "$path/pg_isready" ] && \
               [ -x "$path/psql" ]; then
                export PATH="$path:$PATH"
                log_success "Found PostgreSQL tools at: $path"
                return 0
            fi
        fi
    done

    # No PostgreSQL tools found
    log_error "PostgreSQL tools not found"
    log_info "Please install PostgreSQL:"
    log_info "  macOS: brew install postgresql@16"
    log_info "  Ubuntu/Debian: sudo apt-get install postgresql-client-16"
    log_info "  RedHat/CentOS: sudo yum install postgresql16"
    log_info ""
    log_info "Or set PG_BIN_DIR environment variable to PostgreSQL bin directory"
    return 1
}

# ============================================================================
# Docker Check
# ============================================================================

check_docker() {
    # Load config if not already loaded
    load_db_config

    # Use configured docker command (defaults to "docker")
    local docker_cmd="${DOCKER_COMMAND:-docker}"
    local compose_cmd="${COMPOSE_COMMAND:-docker-compose}"

    # Check if docker command exists
    if ! command -v "$docker_cmd" &> /dev/null; then
        log_error "Docker not found (command: $docker_cmd)"
        log_info "Please install Docker Desktop or set DOCKER_COMMAND in config"
        return 1
    fi

    # Check if compose command exists
    # Try both docker-compose and docker compose
    if ! command -v "$compose_cmd" &> /dev/null && \
       ! $docker_cmd compose version &> /dev/null; then
        log_error "Docker Compose not found (tried: $compose_cmd, docker compose)"
        log_info "Please install Docker Compose or set COMPOSE_COMMAND in config"
        return 1
    fi

    # Check if Docker daemon is running
    if ! $docker_cmd info &> /dev/null; then
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
    # Load config if not already loaded
    load_db_config

    # Use configured prisma command (defaults to "npx prisma")
    local prisma_cmd="${PRISMA_COMMAND:-npx prisma}"

    # Check if prisma command is accessible
    if ! $prisma_cmd --version &> /dev/null; then
        log_error "Prisma CLI not accessible (command: $prisma_cmd)"
        log_info "Please install Prisma:"
        log_info "  npm install -D prisma"
        log_info "Or set PRISMA_COMMAND in config/environment"
        return 1
    fi

    log_success "Prisma CLI is available"
    return 0
}
