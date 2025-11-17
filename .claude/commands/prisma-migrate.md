---
title: "Prisma Migrate"
description: "Automated Prisma schema migration with intelligent naming"
usage: "/prisma-migrate"
---

# Prisma Migration Command

## Overview

Automates Prisma schema migrations with intelligent detection and naming.

This command performs automated Prisma migrations with the following steps:

1. **Detect Migrations**: Automatically finds your Prisma schema and migrations directory
2. **Check Changes**: Detects schema changes and pending migrations
3. **Select Environment**: Prompts for development or production environment
4. **Generate Name**: Automatically generates meaningful migration names (dev only)
5. **Run Migration**: Executes `prisma migrate dev` or `prisma migrate deploy`
6. **Verify**: Confirms migration file creation and application

## Prerequisites

- Node.js and npm must be installed
- Prisma must be installed as a dev dependency
- Prisma schema must exist in `prisma/` directory

## Migration Name Generation

The tool intelligently generates migration names based on schema changes:

- **Add Model**: `add_user_table` (detects new model)
- **Remove Model**: `remove_post_table` (detects deleted model)
- **Add Index**: `add_index` (detects index changes)
- **Generic**: `schema_update_20250118_143052` (fallback with timestamp)

## Environment Modes

### Development Mode
- Creates a new migration file with auto-generated name
- Applies the migration to the database
- Suitable for local development and testing

### Production Mode
- Applies existing migrations only (no new migration file)
- Used for deploying to production databases
- Skips migration name generation

## Safety Features

- **Auto-detection**: Finds schema and migrations automatically
- **Change Detection**: Only runs if changes are detected
- **Interactive**: Prompts for environment selection
- **Logging**: Saves detailed logs to `.claude/cache/prisma-migrate.log`

## Usage

Simply run:

```bash
/prisma-migrate
```

The command will:
1. Detect your Prisma setup automatically
2. Show existing migrations
3. Check for schema changes
4. Prompt for environment (dev/prod)
5. Generate migration name (if dev)
6. Execute the migration
7. Display summary

## Examples

### Basic Usage

```bash
/prisma-migrate
```

The command will interactively prompt you to select the environment (development or production).

### Development Mode Example

```bash
/prisma-migrate
# Select option 1 for development
# Creates and applies new migration
```

### Production Mode Example

```bash
/prisma-migrate
# Select option 2 for production
# Applies existing migrations only
```

### Example Output

```
============================================
  Prisma Migration Tool
============================================

=== Step 0: Detect Migrations Directory ===
✓ Found migrations directory: prisma/schema/migrations
✓ Found schema: prisma/schema/schema.prisma

Existing migrations:
  Total: 12 migration(s)
  Recent migrations:
    - 20250115142030_add_user_table
    - 20250114093015_add_index
    - 20250113151820_schema_update

=== Step 1: Check Schema Changes ===
ℹ️  Schema file has uncommitted changes

=== Step 2: Select Environment ===
Please select the environment:
  1) Development (create migration file + apply)
  2) Production (apply existing migrations only)

Enter choice (1/2): 1
✓ Environment: Development

=== Step 3: Generate Migration Name ===
ℹ️  Analyzing schema changes...
✓ Generated migration name: add_order_table

=== Step 4: Run Migration ===
ℹ️  Running development migration...
✓ Migration created and applied successfully
ℹ️  Migration file: 20250118143052_add_order_table

============================================
✅ Migration Completed!
============================================

ℹ️  Environment: development
ℹ️  Schema: prisma/schema/schema.prisma
ℹ️  Migration name: add_order_table
ℹ️  Total migrations: 13
```

## Error Handling

If migration fails:
- Check the log file at `.claude/cache/prisma-migrate.log`
- Verify your database is running and accessible
- Ensure schema syntax is correct
- Check for conflicts with existing migrations

## Implementation

<bash description="Run Prisma migration">
.claude/lib/prisma-migrate.sh
</bash>
