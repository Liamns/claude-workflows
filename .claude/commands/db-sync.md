---
title: "DB Sync"
description: "Synchronize database from production to development environment"
usage: "/db-sync"
---

# DB Sync Command

## Overview

Synchronizes the database from production (source) to development (target) environment.

This command performs a complete database synchronization with the following steps:

1. **Connection Check**: Verifies connectivity to both source and target databases
2. **Create Dump**: Creates a backup dump from the source database
3. **Create Backup**: Backs up the current target database (keeps last 5 backups)
4. **Initialize Target**: Stops and reinitializes the target database
5. **Restore Data**: Restores the dump to the target database
6. **Verify Data**: Validates the restored data integrity
7. **Cleanup**: Removes temporary files and releases locks

## Prerequisites

- Docker and docker-compose must be running
- PostgreSQL@16 tools must be installed (`brew install postgresql@16`)
- `.env` file must exist with source DATABASE_URL
- `.env.docker` file must exist with target DATABASE_URL

## Safety Features

- **Automatic Backup**: Creates a timestamped backup before any changes
- **Automatic Rollback**: Reverts to the latest backup if restoration fails
- **Lock File**: Prevents multiple simultaneous sync operations
- **Data Verification**: Validates restored data after sync

## Usage

Simply run:

```bash
/db-sync
```

The command will:
- Display progress for each step
- Show detailed logs in `.claude/cache/db-sync.log`
- Report elapsed time upon completion

## Error Handling

If any step fails:
- The script will attempt automatic rollback
- Error messages will indicate the specific failure point
- Check the log file for detailed error information

## Examples

### Basic Usage

```bash
/db-sync
```

### Example Output

```
============================================
  DB Sync - Database Synchronization
============================================

=== Step 0: DB Connection Check ===
✓ PostgreSQL tools available
✓ Source DB: localhost:5433
✓ Target DB: localhost:6022
✓ All DB connections verified

=== Step 1: Create Database Dump ===
✓ Dump created successfully: /tmp/baechaking_backup.dump (155K)

=== Step 2: Create Backup ===
✓ Backup created: postgres/user_backup_20250118_143052

=== Step 3: Initialize Target DB ===
⚠️  This will DESTROY all data in target DB!
✓ Target DB initialized and ready

=== Step 4: Restore Database Dump ===
✓ Dump restored successfully

=== Step 5: Verify Data ===
ℹ️  Tables found: 27
ℹ️  User: 22 records
ℹ️  Order: 110 records
✓ Data verification completed

=== Step 6: Cleanup ===
✓ Cleanup completed

============================================
✅ DB Synchronization Completed!
============================================
ℹ️  Time elapsed: 2m 35s
```

## Implementation

<bash description="Run database synchronization">
.claude/lib/db-sync.sh
</bash>
