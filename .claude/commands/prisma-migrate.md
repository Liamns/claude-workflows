---
title: "Prisma Migrate"
description: "Automated Prisma schema migration with intelligent naming"
usage: "/prisma-migrate"
---

# Prisma Migration Command

## Overview

Automates Prisma schema migrations with intelligent detection and naming.

## Output Language

**IMPORTANT**: 사용자가 확인하는 모든 출력은 반드시 **한글로 작성**해야 합니다.

**한글 작성 대상:**
- 진행 단계 메시지
- 스키마 변경 감지 메시지
- 환경 선택 프롬프트
- 마이그레이션 실행 상태
- 성공/실패 메시지 및 경고

**영어 유지:**
- Prisma 명령어
- 파일 경로
- 마이그레이션 파일명 (타임스탬프_이름)
- 환경 이름 (development, production)

**예시 출력:**
```
============================================
  Prisma 마이그레이션
============================================

=== 단계 0: 마이그레이션 디렉토리 감지 ===
✓ 마이그레이션 디렉토리 발견: prisma/schema/migrations
✓ 스키마 발견: prisma/schema/schema.prisma

기존 마이그레이션:
  총: 12개 마이그레이션
  최근 마이그레이션:
    - 20250115142030_add_user_table
    - 20250114093015_add_index

=== 단계 1: 스키마 변경 확인 ===
ℹ️  스키마 파일에 커밋되지 않은 변경사항 있음

=== 단계 2: 환경 선택 ===
환경을 선택하세요:
  1) Development (마이그레이션 파일 생성 + 적용)
  2) Production (기존 마이그레이션만 적용)

선택 (1/2): 1
✓ 환경: Development

=== 단계 3: 마이그레이션 이름 생성 ===
ℹ️  스키마 변경사항 분석 중...
✓ 마이그레이션 이름 생성: add_order_table

=== 단계 4: 마이그레이션 실행 ===
ℹ️  Development 마이그레이션 실행 중...
✓ 마이그레이션 생성 및 적용 완료
ℹ️  마이그레이션 파일: 20250118143052_add_order_table

============================================
✅ 마이그레이션 완료!
============================================

ℹ️  환경: development
ℹ️  스키마: prisma/schema/schema.prisma
ℹ️  마이그레이션 이름: add_order_table
ℹ️  총 마이그레이션: 13개
```

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
