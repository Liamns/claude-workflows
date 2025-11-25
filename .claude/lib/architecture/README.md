# Architecture Verification System

**버전**: 1.0.0
**Epic**: 006 - Architecture Verification Hybridization
**Feature**: 002 - Quick Check Orchestrator

## 개요

Hybrid 아키텍처 검증 시스템으로, **Bash 기반 Quick Check**와 **TypeScript 기반 Deep Check**를 결합하여 빠르고 효율적인 검증을 제공합니다.

### 핵심 성과

- ⚡ **실행 시간**: ~40ms (목표 <1s의 **25배 빠름**)
- 💰 **토큰 절감**: **0 tokens** (100% 절감)
- ✅ **테스트**: 21/21 PASS (100%)

## 아키텍처

```
.claude/lib/architecture/
├── verify.sh                 # 메인 오케스트레이터
├── quick-check.sh            # Quick Check 실행기
├── quick-check-*.sh          # 아키텍처별 검증 (8개)
├── incremental.sh            # 증분 검증
├── cache-manager.sh          # 캐시 관리
└── __tests__/                # 테스트 스위트
    ├── test-quick-check.sh        # 11/11 PASS
    ├── test-verify-integration.sh # 10/10 PASS
    └── BENCHMARK_RESULTS.md       # 성능 벤치마크
```

## 지원 아키텍처

| 아키텍처 | 타입 | 검증 내용 |
|---------|------|----------|
| **FSD** (Feature-Sliced Design) | Frontend | 레이어 규칙, Public API, 의존성 방향 |
| **Clean Architecture** | Backend/Frontend | 계층 분리, 의존성 역전 |
| **Hexagonal** (Ports & Adapters) | Backend | 핵심-어댑터 분리, 포트 정의 |
| **DDD** (Domain-Driven Design) | Backend | 경계 컨텍스트, 도메인 계층 |
| **Layered** (N-Tier) | Backend | Presentation-Business-Data |
| **NestJS** | Backend | 모듈 구조, 의존성 주입 |
| **Express MVC** | Backend | MVC 패턴, 라우팅 구조 |
| **Serverless** (FaaS) | Backend | 함수 분리, 레이어 관리 |

## 사용법

### 기본 사용

```bash
# Quick Check (자동 감지)
bash .claude/lib/architecture/verify.sh --quick

# 특정 아키텍처 검증
bash .claude/lib/architecture/verify.sh --quick --arch fsd --path src/

# JSON 출력 (CI/CD용)
bash .claude/lib/architecture/verify.sh --quick --json

# 캐시 삭제
bash .claude/lib/architecture/verify.sh --quick --cache-clear
```

### 모드

| 모드 | 설명 | 실행 시간 | 토큰 사용 |
|------|------|----------|----------|
| `--quick` | Bash 기반 빠른 검증 (기본값) | ~40ms | 0 |
| `--deep` | TypeScript AST 기반 상세 검증 | 5-30s | 10,000+ |
| `--both` | Quick + Deep 연속 실행 | - | - |
| `--incremental` | Git diff 기반 변경 파일만 | <2s | <1,000 |

### 옵션

```bash
--quick              # Quick Check만 실행 (기본값)
--deep               # Deep Check만 실행
--both               # Quick + Deep 모두 실행
--incremental        # 증분 검증 (변경 파일만)
--arch TYPE          # 아키텍처 타입 지정 (auto-detect 기본)
--path PATH          # 검증 대상 경로 (기본: src/)
--fix                # 자동 수정 (실험적)
--cache-clear        # 캐시 삭제
--json               # JSON 출력
-v, --verbose        # 상세 출력
-h, --help           # 도움말
```

## 예제

### 1. FSD 프로젝트 검증

```bash
# 자동 감지
bash .claude/lib/architecture/verify.sh --quick --path src/

# 수동 지정
bash .claude/lib/architecture/verify.sh --quick --arch fsd --path src/
```

**출력**:
```
✓ All FSD rules validated successfully
✓ Quick check passed!
```

### 2. CI/CD 통합

```bash
# JSON 출력으로 CI에서 사용
bash .claude/lib/architecture/verify.sh --quick --json

# 결과 (stdout):
{
  "status": "pass",
  "message": "Quick check passed",
  "mode": "quick",
  "path": "src",
  "architecture": "fsd",
  "timestamp": "2025-11-25T00:00:00Z",
  "tool": "verify.sh",
  "version": "1.0.0"
}

# Exit code: 0 (성공)
```

### 3. Git Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running architecture validation..."
bash .claude/lib/architecture/verify.sh --quick --path src/

if [ $? -ne 0 ]; then
  echo "❌ Architecture validation failed"
  exit 1
fi

echo "✅ Architecture validation passed"
```

## 성능

### 벤치마크 결과

| 테스트 | 파일 수 | 실행 시간 | 결과 |
|--------|---------|----------|------|
| FSD Small | 10 | ~40ms | ✅ PASS |
| FSD Medium | 50 | ~45ms | ✅ PASS |
| Clean | 20 | ~40ms | ✅ PASS |
| NestJS | 18 | ~40ms | ✅ PASS |
| Auto-Detection | 50 | ~45ms | ✅ PASS |

**상세 결과**: [BENCHMARK_RESULTS.md](./__tests__/BENCHMARK_RESULTS.md)

### Quick vs Deep 비교

| 메트릭 | Quick Check | Deep Check | 개선율 |
|--------|-------------|------------|--------|
| 실행 시간 | ~40ms | 5-30s | **96%+ 감소** |
| 토큰 사용 | 0 | 10,000+ | **100% 감소** |
| LLM 호출 | 없음 | 필요 | N/A |
| 정확도 | 80-90% | 95-99% | - |

## 검증 규칙

### FSD (Feature-Sliced Design)

**레이어 계층**:
- `app/` - 앱 초기화
- `pages/` - 페이지 라우팅
- `widgets/` - 복합 UI 블록
- `features/` - 사용자 시나리오
- `entities/` - 비즈니스 엔티티
- `shared/` - 공유 유틸리티

**규칙**:
1. ✅ 상위 레이어는 하위 레이어만 import 가능
2. ✅ Shared는 모든 레이어에서 import 가능
3. ✅ 동일 레이어 간 import 금지
4. ✅ Public API를 통한 접근만 허용 (`index.ts`)

### Clean Architecture

**레이어**:
- `domain/` - 도메인 로직 (최내부)
- `application/` - 사용 사례
- `infrastructure/` - 외부 인터페이스
- `presentation/` - UI 레이어

**규칙**:
1. ✅ Domain은 어디에도 의존하지 않음
2. ✅ Application은 Domain만 의존
3. ✅ Infrastructure/Presentation은 Application 의존
4. ✅ 의존성 역전 원칙 (DIP) 준수

### Hexagonal (Ports & Adapters)

**구조**:
- `core/` - 비즈니스 로직
- `adapters/` - 외부 연결
  - `adapters/inbound/` - 입력 어댑터
  - `adapters/outbound/` - 출력 어댑터

**규칙**:
1. ✅ Core는 Adapters에 의존하지 않음
2. ✅ Adapters는 Core에 의존
3. ✅ Port 인터페이스 정의 필수

## 테스트

### 전체 테스트 실행

```bash
# Quick Check Orchestrator 테스트 (11개)
bash .claude/lib/architecture/__tests__/test-quick-check.sh

# verify.sh 통합 테스트 (10개)
bash .claude/lib/architecture/__tests__/test-verify-integration.sh

# 전체: 21/21 PASS
```

### 테스트 커버리지

- ✅ 아키텍처 자동 감지 (FSD, Clean, NestJS, Express)
- ✅ 수동 아키텍처 선택
- ✅ JSON 출력 형식
- ✅ 에러 핸들링 (존재하지 않는 경로, 잘못된 아키텍처)
- ✅ Help/Usage 출력
- ✅ 캐시 기능

## 문제 해결

### Q: 아키텍처가 자동 감지되지 않습니다

**A**: 수동으로 아키텍처를 지정하세요.

```bash
bash .claude/lib/architecture/verify.sh --quick --arch fsd --path src/
```

지원 아키텍처: `fsd`, `clean`, `hexagonal`, `ddd`, `layered`, `nestjs`, `express`, `serverless`

### Q: JSON 출력에 불필요한 메시지가 포함됩니다

**A**: v1.0.0에서 수정되었습니다. JSON 모드에서는 검증 메시지가 억제되고 순수 JSON만 출력됩니다.

### Q: macOS에서 실행 속도가 느립니다

**A**: Quick Check는 Bash만 사용하므로 ~40ms로 매우 빠릅니다. Deep Check를 사용하면 느려질 수 있습니다.

### Q: 캐시를 삭제하고 싶습니다

**A**: `--cache-clear` 옵션을 사용하세요.

```bash
bash .claude/lib/architecture/verify.sh --quick --cache-clear
```

## 확장 가능성

### 새로운 아키텍처 추가

1. `quick-check-{arch}.sh` 파일 생성
2. `validate_{arch}_directory()` 함수 구현
3. `quick-check.sh`의 `detect_architecture()` 업데이트

예제: `quick-check-mvvm.sh`

```bash
#!/bin/bash
# quick-check-mvvm.sh
# MVVM Architecture Quick Check

validate_mvvm_directory() {
  local root_path="$1"

  # MVVM 구조 검증 로직
  # ...

  return 0
}
```

## 개발 정보

### 프로젝트 구조

```
architecture/
├── verify.sh              # 메인 오케스트레이터
├── quick-check.sh         # Quick Check 실행기
├── quick-check-fsd.sh     # FSD 검증
├── quick-check-clean.sh   # Clean Architecture 검증
├── quick-check-hexagonal.sh
├── quick-check-ddd.sh
├── quick-check-layered.sh
├── quick-check-nestjs.sh
├── quick-check-express.sh
├── quick-check-serverless.sh
├── incremental.sh         # 증분 검증
├── cache-manager.sh       # 캐시 관리
└── __tests__/
    ├── test-quick-check.sh
    ├── test-verify-integration.sh
    ├── benchmark-verify.sh
    └── BENCHMARK_RESULTS.md
```

### 의존성

- **Bash** 4.0+
- **Git** (증분 검증용)
- **jq** (JSON 테스트용, 선택적)

### 기여 가이드

1. 새로운 아키텍처 추가 시 테스트 작성
2. 모든 변경사항은 테스트 통과 필수
3. 성능 목표 유지 (<1s for Quick Check)

## 라이선스

MIT License - Claude Workflows 프로젝트의 일부

## 변경 로그

### v1.0.0 (2025-11-25)

**초기 릴리스**:
- ✅ Quick Check 구현 (8개 아키텍처)
- ✅ verify.sh 오케스트레이터
- ✅ 통합 테스트 (21/21 PASS)
- ✅ 성능 벤치마크 (~40ms, 0 tokens)
- ✅ JSON 출력 지원
- ✅ 캐시 관리
- ✅ 증분 검증

**성과**:
- 실행 시간: 96%+ 감소 (5-30s → ~40ms)
- 토큰 사용: 100% 감소 (10,000+ → 0)

---

**문서 작성**: 2025-11-25
**마지막 업데이트**: 2025-11-25
**Epic 006 - Feature 002**: ✅ 완료
