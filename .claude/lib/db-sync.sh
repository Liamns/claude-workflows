#!/bin/bash

# ============================================================================
# DB Sync - Synchronize database from production to development
# ============================================================================

set -e

# ============================================================================
# Setup
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/db-utils.sh"

# ============================================================================
# Constants
# ============================================================================

LOG_FILE=".claude/cache/db-sync.log"
LOCK_FILE="/tmp/db-sync.lock"
DUMP_FILE="/tmp/baechaking_backup.dump"

# ============================================================================
# Lock File Management
# ============================================================================

check_lock_file() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE" 2>/dev/null)

        # Check if process is still running
        if ps -p "$pid" > /dev/null 2>&1; then
            log_error "Another db-sync process is running (PID: $pid)"
            log_info "If this is a stale lock, remove it manually:"
            log_info "  rm $LOCK_FILE"
            return 1
        else
            log_warning "Removing stale lock file (PID $pid not running)"
            rm -f "$LOCK_FILE"
        fi
    fi

    # Create lock file with current PID
    echo $$ > "$LOCK_FILE"
    log_info "Lock file created"
    return 0
}

# ============================================================================
# DB Connection Check
# ============================================================================

check_db_connection() {
    local host="$1"
    local port="$2"
    local user="$3"
    local db="$4"
    local label="$5"

    log_info "Checking connection to $label ($host:$port)..."

    # Primary check using pg_isready
    if pg_isready -h "$host" -p "$port" -U "$user" &> /dev/null; then
        log_success "DB connection successful: $label ($host:$port)"
        return 0
    fi

    # Secondary check using psql if pg_isready fails
    log_warning "pg_isready check failed, trying psql..."

    if PGPASSWORD="$DB_PASS" psql -h "$host" -p "$port" -U "$user" -d "$db" -c "SELECT 1" &> /dev/null; then
        log_success "DB connection successful (via psql): $label ($host:$port)"
        return 0
    fi

    # Both checks failed
    log_error "DB connection failed: $label"
    log_error "  Host: $host"
    log_error "  Port: $port"
    log_error "  User: $user"
    log_error "  Database: $db"
    log_info "Please check:"
    log_info "  1. Database server is running"
    log_info "  2. Connection credentials are correct in .env file"
    log_info "  3. Network connectivity"

    return 1
}

# ============================================================================
# Environment Variable Parsing
# ============================================================================

parse_env_files() {
    log_info "Parsing environment variables..."

    # Check if .env file exists
    if [ ! -f ".env" ]; then
        log_error ".env file not found"
        log_info "Please create .env file with DATABASE_URL"
        return 1
    fi

    # Check if .env.docker file exists
    if [ ! -f ".env.docker" ]; then
        log_error ".env.docker file not found"
        log_info "Please create .env.docker file with DATABASE_URL"
        return 1
    fi

    # Read source DATABASE_URL from .env
    SOURCE_DATABASE_URL=$(grep '^DATABASE_URL=' .env | cut -d '=' -f 2- | tr -d '"' | tr -d "'")
    if [ -z "$SOURCE_DATABASE_URL" ]; then
        log_error "DATABASE_URL not found in .env"
        return 1
    fi

    # Parse source DB
    parse_database_url "$SOURCE_DATABASE_URL"
    SOURCE_DB_HOST="$DB_HOST"
    SOURCE_DB_PORT="$DB_PORT"
    SOURCE_DB_USER="$DB_USER"
    SOURCE_DB_PASS="$DB_PASS"
    SOURCE_DB_NAME="$DB_NAME"

    log_success "Source DB: $SOURCE_DB_HOST:$SOURCE_DB_PORT"

    # Read target DATABASE_URL from .env.docker
    TARGET_DATABASE_URL=$(grep '^DATABASE_URL=' .env.docker | cut -d '=' -f 2- | tr -d '"' | tr -d "'")
    if [ -z "$TARGET_DATABASE_URL" ]; then
        log_error "DATABASE_URL not found in .env.docker"
        return 1
    fi

    # Parse target DB
    parse_database_url "$TARGET_DATABASE_URL"
    TARGET_DB_HOST="$DB_HOST"
    TARGET_DB_PORT="$DB_PORT"
    TARGET_DB_USER="$DB_USER"
    TARGET_DB_PASS="$DB_PASS"
    TARGET_DB_NAME="$DB_NAME"

    log_success "Target DB: $TARGET_DB_HOST:$TARGET_DB_PORT"

    return 0
}

# ============================================================================
# Step 0: Environment Setup and Connection Check
# ============================================================================

step_0_check_connections() {
    echo ""
    log_info "=== Step 0: DB Connection Check ==="
    echo ""

    # Check PostgreSQL tools
    check_postgresql_tools || return 1

    # Parse environment files
    parse_env_files || return 1

    # Check source DB connection
    check_db_connection "$SOURCE_DB_HOST" "$SOURCE_DB_PORT" "$SOURCE_DB_USER" "$SOURCE_DB_NAME" "Source DB" || return 1

    # Check target DB connection
    check_db_connection "$TARGET_DB_HOST" "$TARGET_DB_PORT" "$TARGET_DB_USER" "$TARGET_DB_NAME" "Target DB" || return 1

    log_success "All DB connections verified"
    return 0
}

# ============================================================================
# .pgpass File Management
# ============================================================================

PGPASS_FILE="/tmp/.pgpass_$$"

setup_pgpass() {
    local host="$1"
    local port="$2"
    local db="$3"
    local user="$4"
    local pass="$5"

    echo "$host:$port:$db:$user:$pass" > "$PGPASS_FILE"
    chmod 600 "$PGPASS_FILE"
    export PGPASSFILE="$PGPASS_FILE"

    log_info ".pgpass file created for secure authentication"
}

cleanup_pgpass() {
    if [ -f "$PGPASS_FILE" ]; then
        rm -f "$PGPASS_FILE"
        unset PGPASSFILE
        log_info ".pgpass file removed"
    fi
}

# ============================================================================
# Step 1: Create Dump
# ============================================================================

create_dump() {
    echo ""
    log_info "=== Step 1: Create Database Dump ==="
    echo ""

    log_info "Creating dump from source DB..."
    log_info "  Host: $SOURCE_DB_HOST:$SOURCE_DB_PORT"
    log_info "  Database: $SOURCE_DB_NAME"

    # Setup .pgpass for secure authentication
    setup_pgpass "$SOURCE_DB_HOST" "$SOURCE_DB_PORT" "$SOURCE_DB_NAME" "$SOURCE_DB_USER" "$SOURCE_DB_PASS"

    # Create dump with retry logic (max 3 attempts)
    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if PGPASSWORD="$SOURCE_DB_PASS" pg_dump \
            -h "$SOURCE_DB_HOST" \
            -p "$SOURCE_DB_PORT" \
            -U "$SOURCE_DB_USER" \
            -d "$SOURCE_DB_NAME" \
            -F c \
            -f "$DUMP_FILE"; then

            # Check if dump file was created
            if [ -f "$DUMP_FILE" ]; then
                local file_size=$(du -h "$DUMP_FILE" | cut -f1)
                log_success "Dump created successfully: $DUMP_FILE ($file_size)"
                return 0
            else
                log_error "Dump file was not created"
                ((retry_count++))
                if [ $retry_count -lt $max_retries ]; then
                    log_warning "Retrying... (Attempt $((retry_count + 1))/$max_retries)"
                    sleep 2
                fi
            fi
        else
            log_error "pg_dump command failed"
            ((retry_count++))
            if [ $retry_count -lt $max_retries ]; then
                log_warning "Retrying... (Attempt $((retry_count + 1))/$max_retries)"
                sleep 2
            fi
        fi
    done

    log_error "Failed to create dump after $max_retries attempts"
    return 1
}

# ============================================================================
# Step 2: Create Backup
# ============================================================================

create_backup() {
    echo ""
    log_info "=== Step 2: Create Backup ==="
    echo ""

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="postgres/user_backup_$timestamp"

    log_info "Creating backup of current data..."
    log_info "  Source: postgres/user"
    log_info "  Destination: $backup_dir"

    # Check if source directory exists
    if [ ! -d "postgres/user" ]; then
        log_warning "Source directory postgres/user does not exist"
        log_info "Skipping backup creation (this is normal for first-time setup)"
        return 0
    fi

    # Create backup
    if cp -r postgres/user "$backup_dir"; then
        log_success "Backup created: $backup_dir"

        # Cleanup old backups (keep only last 5)
        cleanup_old_backups
        return 0
    else
        log_error "Failed to create backup"
        return 1
    fi
}

cleanup_old_backups() {
    log_info "Cleaning up old backups (keeping last 5)..."

    # Find all backup directories and sort by modification time
    local backups=($(ls -dt postgres/user_backup_* 2>/dev/null || true))
    local backup_count=${#backups[@]}

    if [ $backup_count -le 5 ]; then
        log_info "No cleanup needed ($backup_count backups)"
        return 0
    fi

    # Remove old backups (keep only last 5)
    local to_remove=$((backup_count - 5))
    log_info "Removing $to_remove old backup(s)..."

    for ((i=5; i<backup_count; i++)); do
        local old_backup="${backups[$i]}"
        log_info "  Removing: $old_backup"
        rm -rf "$old_backup"
    done

    log_success "Old backups cleaned up"
}

# ============================================================================
# Step 3: Initialize Target DB
# ============================================================================

initialize_target_db() {
    echo ""
    log_info "=== Step 3: Initialize Target DB ==="
    echo ""

    log_warning "This will DESTROY all data in target DB!"
    log_info "Stopping postgres_dev container..."
    docker-compose stop postgres_dev || log_warning "Container may not be running"

    log_info "Removing postgres/user directory..."
    rm -rf postgres/user

    log_info "Creating fresh postgres/user directory..."
    mkdir -p postgres/user

    log_info "Starting postgres_dev container..."
    docker-compose up -d postgres_dev

    log_info "Waiting for database to be ready (8 seconds)..."
    sleep 8

    # Verify DB is ready
    if docker logs baechaking-api-postgres_dev-1 2>&1 | grep -q "ready to accept connections"; then
        log_success "Target DB initialized and ready"
        return 0
    else
        log_error "Target DB may not be ready"
        log_warning "Check docker logs: docker logs baechaking-api-postgres_dev-1"
        return 1
    fi
}

# ============================================================================
# Step 4: Restore Dump
# ============================================================================

restore_dump() {
    echo ""
    log_info "=== Step 4: Restore Database Dump ==="
    echo ""

    log_info "Restoring dump to target DB..."
    log_info "  Host: $TARGET_DB_HOST:$TARGET_DB_PORT"
    log_info "  Database: $TARGET_DB_NAME"

    # Setup .pgpass for target DB
    setup_pgpass "$TARGET_DB_HOST" "$TARGET_DB_PORT" "$TARGET_DB_NAME" "$TARGET_DB_USER" "$TARGET_DB_PASS"

    # Create log directory if needed
    mkdir -p .claude/cache

    # Restore with logging
    if PGPASSWORD="$TARGET_DB_PASS" pg_restore \
        -h "$TARGET_DB_HOST" \
        -p "$TARGET_DB_PORT" \
        -U "$TARGET_DB_USER" \
        -d "$TARGET_DB_NAME" \
        --no-owner \
        --no-acl \
        -v \
        "$DUMP_FILE" 2>&1 | tee -a "$LOG_FILE"; then

        log_success "Dump restored successfully"
        return 0
    else
        log_error "Failed to restore dump"
        log_info "Check log file: $LOG_FILE"
        return 1
    fi
}

# ============================================================================
# Step 5: Verify Data
# ============================================================================

verify_data() {
    echo ""
    log_info "=== Step 5: Verify Data ==="
    echo ""

    log_info "Verifying restored data..."

    # Count tables
    local table_count=$(PGPASSWORD="$TARGET_DB_PASS" psql \
        -h "$TARGET_DB_HOST" \
        -p "$TARGET_DB_PORT" \
        -U "$TARGET_DB_USER" \
        -d "$TARGET_DB_NAME" \
        -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')

    log_info "Tables found: $table_count"

    # Verify key tables exist and have data
    local tables=("User" "Order" "Shipper" "Carrier")

    for table in "${tables[@]}"; do
        local count=$(PGPASSWORD="$TARGET_DB_PASS" psql \
            -h "$TARGET_DB_HOST" \
            -p "$TARGET_DB_PORT" \
            -U "$TARGET_DB_USER" \
            -d "$TARGET_DB_NAME" \
            -t -c "SELECT COUNT(*) FROM \"$table\";" 2>/dev/null | tr -d ' ' || echo "0")

        if [ "$count" != "0" ]; then
            log_info "$table: $count records"
        else
            log_warning "$table: No records found (may not exist)"
        fi
    done

    log_success "Data verification completed"
    return 0
}

# ============================================================================
# Step 6: Cleanup
# ============================================================================

cleanup() {
    echo ""
    log_info "=== Step 6: Cleanup ==="
    echo ""

    log_info "Cleaning up temporary files..."

    # Remove dump file
    if [ -f "$DUMP_FILE" ]; then
        rm -f "$DUMP_FILE"
        log_info "Dump file removed: $DUMP_FILE"
    fi

    # Remove lock file
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
        log_info "Lock file removed: $LOCK_FILE"
    fi

    # Cleanup .pgpass
    cleanup_pgpass

    log_success "Cleanup completed"
}

# ============================================================================
# Rollback Function
# ============================================================================

rollback() {
    echo ""
    log_error "=== ROLLBACK: Restoring from Backup ==="
    echo ""

    # Find most recent backup
    local recent_backup=$(ls -dt postgres/user_backup_* 2>/dev/null | head -1)

    if [ -z "$recent_backup" ]; then
        log_error "No backup found for rollback!"
        log_error "Manual intervention required"
        return 1
    fi

    log_info "Found backup: $recent_backup"
    log_info "Stopping postgres_dev container..."
    docker-compose stop postgres_dev || true

    log_info "Removing current postgres/user..."
    rm -rf postgres/user

    log_info "Restoring from backup..."
    cp -r "$recent_backup" postgres/user

    log_info "Starting postgres_dev container..."
    docker-compose up -d postgres_dev

    log_info "Waiting for database to be ready..."
    sleep 8

    log_success "Rollback completed"
    log_info "Database restored to: $recent_backup"
    return 0
}

# ============================================================================
# Main Function
# ============================================================================

main() {
    local start_time=$(date +%s)

    # Print header
    echo ""
    echo "============================================"
    echo "  DB Sync - Database Synchronization"
    echo "============================================"
    echo ""

    # Setup trap for cleanup
    trap cleanup EXIT
    trap 'log_error "Script interrupted"; cleanup; exit 1' INT TERM

    # Step 0: Check connections
    if ! check_lock_file; then
        exit 1
    fi

    if ! step_0_check_connections; then
        cleanup
        exit 1
    fi

    # Step 1: Create dump
    if ! create_dump; then
        cleanup
        exit 1
    fi

    # Step 2: Create backup
    if ! create_backup; then
        cleanup
        exit 1
    fi

    # Step 3: Initialize target DB
    if ! initialize_target_db; then
        cleanup
        exit 1
    fi

    # Step 4: Restore dump (with rollback on failure)
    if ! restore_dump; then
        log_error "Restore failed! Attempting rollback..."
        rollback
        cleanup
        exit 1
    fi

    # Step 5: Verify data
    if ! verify_data; then
        log_warning "Verification failed, but data may be partially restored"
    fi

    # Step 6 is handled by trap

    # Calculate elapsed time
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))

    echo ""
    echo "============================================"
    log_success "✅ DB Synchronization Completed!"
    echo "============================================"
    log_info "Time elapsed: ${minutes}m ${seconds}s"
    echo ""

    exit 0
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
