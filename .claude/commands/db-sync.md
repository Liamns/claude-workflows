---
title: "DB Sync"
description: "Synchronize database from production to development environment"
usage: "/db-sync"
---

# DB Sync Command

**Claude를 위한 필수 지시사항:**

이 명령어가 실행될 때 반드시 다음 단계를 **순서대로** 따라야 합니다:

1. 사전 조건 확인 (.env, .env.docker 파일 존재, Docker 실행 중)
2. .claude/lib/db-sync.sh 스크립트 실행
3. 결과를 파싱하고 표시
4. 에러 발생 시 트러블슈팅 가이드 제공
5. AskUserQuestion을 사용하여 다음 단계 권장사항 제공

**절대로 사전 조건 확인 단계를 건너뛰지 마세요.**

---

## 📋 다음 단계 추천

이 명령어는 일반적으로 **최종 작업**이므로 다음 단계 추천이 없습니다.
DB 동기화 완료 후 필요에 따라 수동으로 다른 작업을 진행하세요.

---

## Overview

프로덕션(소스)에서 개발(타겟) 환경으로 데이터베이스를 동기화합니다.

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

이 커맨드는 다음 단계로 완전한 데이터베이스 동기화를 수행합니다:

1. **연결 확인**: 소스 및 타겟 데이터베이스 연결 확인
2. **덤프 생성**: 소스 데이터베이스에서 백업 덤프 생성
3. **백업 생성**: 현재 타겟 데이터베이스 백업 (최근 5개 백업 유지)
4. **타겟 초기화**: 타겟 데이터베이스 중지 및 재초기화
5. **데이터 복원**: 타겟 데이터베이스에 덤프 복원
6. **데이터 검증**: 복원된 데이터 무결성 확인
7. **정리**: 임시 파일 제거 및 잠금 해제

## Prerequisites

- Docker와 docker-compose가 실행 중이어야 함
- PostgreSQL@16 도구가 설치되어 있어야 함 (`brew install postgresql@16`)
- 소스 DATABASE_URL이 포함된 `.env` 파일이 존재해야 함
- 타겟 DATABASE_URL이 포함된 `.env.docker` 파일이 존재해야 함

## Safety Features

- **자동 백업**: 변경 전 타임스탬프가 포함된 백업 생성
- **자동 롤백**: 복원 실패 시 최신 백업으로 되돌림
- **잠금 파일**: 여러 동기화 작업이 동시에 실행되는 것을 방지
- **데이터 검증**: 동기화 후 복원된 데이터 검증

## Usage

다음과 같이 실행합니다:

```bash
/db-sync
```

커맨드는 다음을 수행합니다:
- 각 단계의 진행 상황 표시
- `.claude/cache/db-sync.log`에 상세 로그 표시
- 완료 시 경과 시간 보고

## Error Handling

단계가 실패하는 경우:
- 스크립트가 자동 롤백 시도
- 에러 메시지가 구체적인 실패 지점 표시
- 상세한 에러 정보는 로그 파일 확인

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
