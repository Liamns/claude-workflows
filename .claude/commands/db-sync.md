---
title: "DB Sync"
description: "Synchronize database from production to development environment"
usage: "/db-sync"
---

# DB Sync Command

## Overview

Synchronizes the database from production (source) to development (target) environment.

## Output Language

**IMPORTANT**: 사용자가 확인하는 모든 출력은 반드시 **한글로 작성**해야 합니다.

**한글 작성 대상:**
- 진행 단계 메시지
- 성공/실패 상태
- 검증 결과
- 에러 메시지 및 경고

**영어 유지:**
- 데이터베이스 이름
- 파일 경로
- 명령어

**예시 출력:**
```
============================================
  DB 동기화 - 데이터베이스 동기화
============================================

=== 단계 0: DB 연결 확인 ===
✓ PostgreSQL 도구 사용 가능
✓ 소스 DB: localhost:5433
✓ 타겟 DB: localhost:6022
✓ 모든 DB 연결 확인 완료

=== 단계 1: 데이터베이스 덤프 생성 ===
✓ 덤프 생성 완료: /tmp/baechaking_backup.dump (155K)

=== 단계 5: 데이터 검증 ===
ℹ️  테이블 발견: 27개
ℹ️  User: 22개 레코드
ℹ️  Order: 110개 레코드
✓ 데이터 검증 완료
```

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
