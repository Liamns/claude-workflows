---
title: "Prisma Migrate"
description: "Automated Prisma schema migration with intelligent naming"
usage: "/prisma-migrate"
---

# Prisma Migration Command

**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. 사전 조건 확인 (Prisma 스키마 변경사항 - git diff schema.prisma)
2. .claude/lib/prisma-migrate.sh 스크립트 실행
3. 결과를 파싱하고 표시
4. 마이그레이션 히스토리와 비교
5. AskUserQuestion을 사용하여 다음 단계 권장사항 제공

**절대로 사전 조건 확인 단계를 건너뛰지 마세요.**

---

## Overview

지능형 감지와 네이밍을 통해 Prisma 스키마 마이그레이션(migration)을 자동화합니다.

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

이 커맨드는 다음 단계로 Prisma 마이그레이션(migration)을 자동화합니다:

1. **마이그레이션 감지**: Prisma 스키마와 마이그레이션 디렉토리를 자동으로 찾습니다
2. **변경 확인**: 스키마 변경 사항과 대기 중인 마이그레이션을 감지합니다
3. **환경 선택**: 개발(development) 또는 프로덕션(production) 환경을 선택하도록 안내합니다
4. **이름 생성**: 의미 있는 마이그레이션 이름을 자동으로 생성합니다 (개발 환경만)
5. **마이그레이션 실행**: `prisma migrate dev` 또는 `prisma migrate deploy`를 실행합니다
6. **검증**: 마이그레이션 파일 생성 및 적용을 확인합니다

## Prerequisites

- Node.js와 npm이 설치되어 있어야 함
- Prisma가 개발 의존성(dev dependency)으로 설치되어 있어야 함
- Prisma 스키마가 `prisma/` 디렉토리에 존재해야 함

## Migration Name Generation

도구가 스키마 변경 사항을 기반으로 마이그레이션 이름을 지능적으로 생성합니다:

- **모델 추가**: `add_user_table` (새 모델 감지)
- **모델 제거**: `remove_post_table` (삭제된 모델 감지)
- **인덱스 추가**: `add_index` (인덱스 변경 감지)
- **일반**: `schema_update_20250118_143052` (타임스탬프가 포함된 기본값)

## Environment Modes

### Development Mode
- 자동 생성된 이름으로 새 마이그레이션 파일 생성
- 데이터베이스에 마이그레이션 적용
- 로컬 개발 및 테스트에 적합

### Production Mode
- 기존 마이그레이션만 적용 (새 마이그레이션 파일 생성 안 함)
- 프로덕션 데이터베이스 배포에 사용
- 마이그레이션 이름 생성 생략

## Safety Features

- **자동 감지**: 스키마와 마이그레이션을 자동으로 찾습니다
- **변경 감지**: 변경 사항이 감지된 경우에만 실행
- **대화형**: 환경 선택을 위한 프롬프트 제공
- **로깅**: 상세 로그를 `.claude/cache/prisma-migrate.log`에 저장

## Usage

다음과 같이 실행합니다:

```bash
/prisma-migrate
```

커맨드는 다음을 수행합니다:
1. Prisma 설정을 자동으로 감지
2. 기존 마이그레이션 표시
3. 스키마 변경 사항 확인
4. 환경(dev/prod) 선택 프롬프트
5. 마이그레이션 이름 생성 (개발 환경인 경우)
6. 마이그레이션 실행
7. 요약 표시

## Examples

### Basic Usage

```bash
/prisma-migrate
```

커맨드가 환경(개발 또는 프로덕션)을 선택하도록 대화형으로 안내합니다.

### Development Mode Example

```bash
/prisma-migrate
# 개발 환경을 위해 옵션 1 선택
# 새 마이그레이션 생성 및 적용
```

### Production Mode Example

```bash
/prisma-migrate
# 프로덕션을 위해 옵션 2 선택
# 기존 마이그레이션만 적용
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

마이그레이션이 실패하는 경우:
- `.claude/cache/prisma-migrate.log`의 로그 파일 확인
- 데이터베이스가 실행 중이고 접근 가능한지 확인
- 스키마 문법이 올바른지 확인
- 기존 마이그레이션과의 충돌 확인

## Implementation

<bash description="Run Prisma migration">
.claude/lib/prisma-migrate.sh
</bash>
