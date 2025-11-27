#!/bin/bash

# ============================================================================
# Prisma Migration - Automated Prisma schema migration tool
# ============================================================================

set -e

# ============================================================================
# Setup
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/db-utils.sh"

# ============================================================================
# Global Variables
# ============================================================================

MIGRATIONS_DIR=""
SCHEMA_PATH=""
ENVIRONMENT=""
MIGRATION_NAME=""

# ============================================================================
# Step 0: Detect migrations Directory
# ============================================================================

detect_migrations_dir() {
    echo ""
    log_info "=== Step 0: Detect Migrations Directory ==="
    echo ""

    log_info "Searching for migrations directory..."

    # Find migrations directory
    MIGRATIONS_DIR=$(find prisma/ -type d -name migrations -print -quit 2>/dev/null)

    if [ -z "$MIGRATIONS_DIR" ]; then
        log_error "No migrations directory found"
        log_info "Please ensure your Prisma schema is set up correctly"
        log_info "Expected path: prisma/*/migrations"
        return 1
    fi

    log_success "Found migrations directory: $MIGRATIONS_DIR"

    # Infer schema path
    local schema_dir
    schema_dir=$(dirname "$MIGRATIONS_DIR")
    SCHEMA_PATH="$schema_dir/schema.prisma"

    # Verify schema file exists
    if [ ! -f "$SCHEMA_PATH" ]; then
        log_warning "schema.prisma not found at expected location: $SCHEMA_PATH"
        log_info "Searching for schema.prisma..."

        SCHEMA_PATH=$(find prisma/ -name "schema.prisma" -print -quit 2>/dev/null)

        if [ -z "$SCHEMA_PATH" ]; then
            log_error "schema.prisma not found"
            return 1
        fi
    fi

    log_success "Found schema: $SCHEMA_PATH"

    # List existing migrations
    list_migrations

    return 0
}

list_migrations() {
    echo ""
    log_info "Existing migrations:"

    local migration_count
    migration_count=$(find "$MIGRATIONS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')

    if [ "$migration_count" -eq 0 ]; then
        log_info "  No migrations found (this is normal for initial setup)"
        return 0
    fi

    log_info "  Total: $migration_count migration(s)"

    # Show last 5 migrations
    log_info "  Recent migrations:"
    find "$MIGRATIONS_DIR" -mindepth 1 -maxdepth 1 -type d | \
        sort -r | \
        head -5 | \
        while read -r migration; do
            local name
            name=$(basename "$migration")
            log_info "    - $name"
        done
}

# ============================================================================
# Step 1: Check Schema Changes
# ============================================================================

check_schema_changes() {
    echo ""
    log_info "=== Step 1: Check Schema Changes ==="
    echo ""

    log_info "Checking Prisma migration status..."

    # Check migration status
    local status_output
    status_output=$(npx prisma migrate status --schema="$SCHEMA_PATH" 2>&1 || true)

    # Check if schema is up to date
    if echo "$status_output" | grep -q "Database schema is up to date"; then
        log_info "Database schema is up to date"

        # Check git diff for schema changes
        if git diff --quiet HEAD "$SCHEMA_PATH" 2>/dev/null; then
            log_success "No schema changes detected"
            log_info "Nothing to migrate"
            return 1  # Return 1 to indicate no changes (not an error, just early exit)
        else
            log_info "Schema file has uncommitted changes"
            # Continue to migration
        fi
    elif echo "$status_output" | grep -q "have not yet been applied"; then
        log_warning "Pending migrations detected"
        log_info "Some migrations have not been applied to the database"
        # Continue to migration
    else
        log_info "Schema status could not be determined, proceeding with migration check..."
    fi

    return 0
}

# ============================================================================
# Step 2: Select Environment
# ============================================================================

# 환경별 .env 파일 감지
detect_env_files() {
    local env_files=()

    # 프로젝트 루트의 .env* 파일 검색
    shopt -s nullglob
    for env_file in .env .env.local .env.development .env.dev .env.staging .env.production .env.prod; do
        if [ -f "$env_file" ]; then
            env_files+=("$env_file")
        fi
    done
    shopt -u nullglob

    # 결과 출력 (newline-separated)
    printf '%s\n' "${env_files[@]}"
}

select_environment() {
    echo ""
    log_info "=== Step 2: Select Environment ==="
    echo ""

    # .env 파일 감지
    local env_files
    env_files=$(detect_env_files)

    if [ -n "$env_files" ]; then
        log_info "감지된 환경 파일:"
        echo "$env_files" | while read -r file; do
            [ -n "$file" ] && log_info "  - $file"
        done
        echo ""

        # 감지된 파일 목록을 stdout으로 출력 (Claude가 파싱)
        echo "ENV_FILES_DETECTED:$(echo "$env_files" | tr '\n' ',')"
    fi

    echo "Please select the environment:"
    echo "  1) Development (create migration file + apply)"
    echo "  2) Production (apply existing migrations only)"
    echo ""

    read -r -p "Enter choice (1/2): " env_choice

    case "$env_choice" in
        1)
            ENVIRONMENT="development"
            log_success "Environment: Development"
            ;;
        2)
            ENVIRONMENT="production"
            log_success "Environment: Production"
            ;;
        *)
            log_error "Invalid choice: $env_choice"
            log_info "Please enter 1 or 2"
            return 1
            ;;
    esac

    return 0
}

# ============================================================================
# Step 3: Generate Migration Name
# ============================================================================

generate_migration_name() {
    echo ""
    log_info "=== Step 3: Generate Migration Name ==="
    echo ""

    if [ "$ENVIRONMENT" = "production" ]; then
        log_info "Skipping migration name generation (production environment)"
        return 0
    fi

    log_info "Analyzing schema changes..."

    # Get git diff of schema
    local diff_output
    diff_output=$(git diff HEAD "$SCHEMA_PATH" 2>/dev/null || echo "")

    if [ -z "$diff_output" ]; then
        log_warning "No git diff available, using default name"
        MIGRATION_NAME="schema_update_$(date +%Y%m%d_%H%M%S)"
        log_info "Migration name: $MIGRATION_NAME"
        return 0
    fi

    # Analyze diff for patterns
    if echo "$diff_output" | grep -q "^+.*model "; then
        local model_name
        model_name=$(echo "$diff_output" | grep "^+.*model " | head -1 | sed 's/.*model \([A-Za-z0-9_]*\).*/\1/')
        MIGRATION_NAME="add_${model_name,,}_table"
    elif echo "$diff_output" | grep -q "^-.*model "; then
        local model_name
        model_name=$(echo "$diff_output" | grep "^-.*model " | head -1 | sed 's/.*model \([A-Za-z0-9_]*\).*/\1/')
        MIGRATION_NAME="remove_${model_name,,}_table"
    elif echo "$diff_output" | grep -q "@@index"; then
        MIGRATION_NAME="add_index"
    else
        MIGRATION_NAME="schema_update_$(date +%Y%m%d_%H%M%S)"
    fi

    log_success "Generated migration name: $MIGRATION_NAME"
    return 0
}

# ============================================================================
# Step 4: Run Migration
# ============================================================================

run_migration() {
    echo ""
    log_info "=== Step 4: Run Migration ==="
    echo ""

    # Create log directory
    mkdir -p .claude/cache

    if [ "$ENVIRONMENT" = "development" ]; then
        log_info "Running development migration..."
        log_info "  Migration name: $MIGRATION_NAME"
        log_info "  Schema: $SCHEMA_PATH"

        # Run prisma migrate dev
        if npx prisma migrate dev \
            --name "$MIGRATION_NAME" \
            --schema="$SCHEMA_PATH" \
            2>&1 | tee -a .claude/cache/prisma-migrate.log; then

            log_success "Migration created and applied successfully"

            # Verify migration file was created
            local new_migration
            new_migration=$(find "$MIGRATIONS_DIR" -type d -name "*_${MIGRATION_NAME}" | head -1)
            if [ -n "$new_migration" ]; then
                log_info "Migration file: $(basename "$new_migration")"
            fi

            return 0
        else
            log_error "Migration failed"
            log_info "Check log: .claude/cache/prisma-migrate.log"
            return 1
        fi

    elif [ "$ENVIRONMENT" = "production" ]; then
        log_info "Running production migration (deploy)..."
        log_info "  Schema: $SCHEMA_PATH"

        # Run prisma migrate deploy
        if npx prisma migrate deploy \
            --schema="$SCHEMA_PATH" \
            2>&1 | tee -a .claude/cache/prisma-migrate.log; then

            log_success "Migrations deployed successfully"
            return 0
        else
            log_error "Migration deployment failed"
            log_info "Check log: .claude/cache/prisma-migrate.log"
            return 1
        fi
    fi

    return 1
}

# ============================================================================
# Step 5: Show Summary
# ============================================================================

show_summary() {
    echo ""
    echo "============================================"
    log_success "✅ Migration Completed!"
    echo "============================================"
    echo ""
    log_info "Environment: $ENVIRONMENT"
    log_info "Schema: $SCHEMA_PATH"
    log_info "Migrations directory: $MIGRATIONS_DIR"

    if [ "$ENVIRONMENT" = "development" ] && [ -n "$MIGRATION_NAME" ]; then
        log_info "Migration name: $MIGRATION_NAME"
    fi

    # Count total migrations
    local migration_count
    migration_count=$(find "$MIGRATIONS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    log_info "Total migrations: $migration_count"

    echo ""
}

# ============================================================================
# Main Function
# ============================================================================

main() {
    # Print header
    echo ""
    echo "============================================"
    echo "  Prisma Migration Tool"
    echo "============================================"
    echo ""

    # Check Prisma CLI
    check_prisma || exit 1

    # Step 0: Detect migrations directory
    if ! detect_migrations_dir; then
        exit 1
    fi

    # Step 1: Check schema changes
    if ! check_schema_changes; then
        # No changes detected, exit gracefully
        exit 0
    fi

    # Step 2: Select environment
    if ! select_environment; then
        exit 1
    fi

    # Step 3: Generate migration name (dev only)
    if ! generate_migration_name; then
        exit 1
    fi

    # Step 4: Run migration
    if ! run_migration; then
        exit 1
    fi

    # Step 5: Show summary
    show_summary

    exit 0
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
