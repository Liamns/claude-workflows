# 문서 및 설치 검증 시스템

## 메타데이터
- 브랜치: 001-documentation-install-validation
- 생성일: 2025-11-10
- 상태: 초안
- 우선순위: P1
- 예상 소요시간: 5-7일

## 개요

이 검증 시스템은 claude-workflows 프로젝트 전체에서 문서와 실제 구현 간의 완전한 일관성을 보장합니다. 모든 명령어 문서(`.claude/commands/*.md`)가 실제 동작을 정확히 반영하는지 자동으로 검증하고, 설치 스크립트(`install.sh`, 마이그레이션 스크립트)가 이전 버전(v1.0, v2.4)에서 현재 버전(v2.5)으로의 모든 업그레이드 시나리오를 올바르게 처리하는지 확인합니다.

이 시스템은 문서의 불일치를 방지하고 이전 버전에서 업그레이드하는 사용자들에게 안정적인 설치/마이그레이션 경험을 보장하기 위한 지속적인 검증을 제공합니다.

## 사용자 시나리오 및 테스트

### [P1] 핵심 기능

#### US1: 문서-코드 일관성 검증
**Given:** 슬래시 명령어 문서 파일이 존재함 (예: `.claude/commands/major.md`)
**When:** 검증 스크립트가 문서화된 워크플로우 단계를 분석하고 실제 구현과 비교함
**Then:** 스크립트는 100% 일치를 보고하거나 파일:줄 번호 참조와 함께 구체적인 불일치를 식별함

**테스트 검증:**
- [ ] 10개의 모든 슬래시 명령어가 실제 동작과 비교 검증됨
- [ ] 불일치는 정확한 파일 위치와 함께 보고됨
- [ ] 문서에서 누락된 단계가 표시됨
- [ ] 문서의 추가/더 이상 사용되지 않는 내용이 식별됨

#### US2: 마이그레이션 시나리오 검증
**Given:** 설치 스크립트가 존재함 (`install.sh`, `migrate-v1-to-v2.sh`, `migrate-v2-to-v25.sh`)
**When:** 검증이 v1.0 및 v2.4 상태에서의 설치를 시뮬레이션함
**Then:** 모든 마이그레이션 시나리오가 오류 없이 성공적으로 실행되고 더 이상 사용되지 않는 파일이 적절히 정리됨

**테스트 검증:**
- [ ] v1.0 → v2.5 업그레이드 시나리오 통과
- [ ] v2.4 → v2.5 업그레이드 시나리오 통과
- [ ] 새로 설치 (이전 버전 없음) 시나리오 통과
- [ ] 더 이상 사용되지 않는 파일이 모든 시나리오에서 올바르게 제거됨
- [ ] 마이그레이션 후 모든 중요 파일이 존재함
- [ ] 버전 추적 (`.claude/.version`)이 올바르게 업데이트됨

#### US3: 교차 참조 검증
**Given:** 여러 문서 파일이 서로를 참조함
**When:** 검증 스크립트가 모든 내부 링크와 참조를 확인함
**Then:** 모든 링크가 유효하고 존재하는 콘텐츠를 가리킴

**테스트 검증:**
- [ ] 사양 내의 모든 마크다운 링크가 검증됨
- [ ] 명령어 간 교차 참조가 확인됨
- [ ] 명령어 문서의 에이전트/스킬 참조가 검증됨
- [ ] 워크플로우 문서의 템플릿 참조가 확인됨

## 기능 요구사항

### 문서 검증
- FR-001: 시스템은 모든 `.claude/commands/*.md` 파일을 파싱하고 문서화된 워크플로우를 추출해야 함
- FR-002: 시스템은 문서화된 단계를 해당 파일의 실제 구현과 비교해야 함
- FR-003: 시스템은 일관성 백분율과 상세한 불일치를 보고해야 함
- FR-004: 시스템은 문서의 예제가 실행 가능한지 검증해야 함

### 마이그레이션 검증
- FR-005: 시스템은 v1.0 환경을 시뮬레이션하고 v2.5로의 업그레이드를 테스트해야 함
- FR-006: 시스템은 v2.4 환경을 시뮬레이션하고 v2.5로의 업그레이드를 테스트해야 함
- FR-007: 시스템은 `cleanup_before_migration()`이 더 이상 사용되지 않는 파일을 올바르게 제거하는지 검증해야 함
- FR-008: 시스템은 모든 마이그레이션 스크립트(`migrate-*.sh`)가 오류 없이 실행되는지 검증해야 함
- FR-009: 시스템은 버전 감지(`detect_installation()`)가 올바르게 작동하는지 검증해야 함
- FR-010: 시스템은 `health_check()`가 설치 상태를 정확하게 보고하는지 확인해야 함

### 교차 참조 검증
- FR-011: 시스템은 모든 마크다운 링크를 추출하고 대상이 존재하는지 확인해야 함
- FR-012: 시스템은 에이전트, 스킬, 템플릿에 대한 참조를 검증해야 함
- FR-013: 시스템은 문서의 참조된 파일 경로가 정확한지 확인해야 함

## 핵심 엔티티

### ValidationReport (검증 보고서)
**속성:**
- id: string - 고유 보고서 식별자
- timestamp: Date - 검증 실행 시간
- documentationResults: DocumentValidation[] - 각 명령어 문서의 결과
- migrationResults: MigrationValidation[] - 각 마이그레이션 시나리오의 결과
- crossReferenceResults: CrossRefValidation[] - 링크 검증 결과
- overallStatus: 'PASS' | 'FAIL' | 'WARNING' - 전체 검증 상태
- consistencyScore: number - 문서 정확도 백분율 (0-100)

**관계:**
- 여러 DocumentValidation 레코드 포함
- 여러 MigrationValidation 레코드 포함
- 여러 CrossRefValidation 레코드 포함

**검증 규칙:**
- consistencyScore는 0-100 사이여야 함
- 중요한 검증이 실패하면 overallStatus는 FAIL
- 중요하지 않은 문제가 있으면 overallStatus는 WARNING
- timestamp는 ISO 8601 형식이어야 함

### DocumentValidation (문서 검증)
**속성:**
- commandName: string - 명령어 이름 (예: "major", "triage")
- filePath: string - `.md` 파일 경로
- extractedSteps: string[] - 문서에서 추출한 단계
- actualImplementation: string[] - 실제 코드에서 발견된 단계
- matches: Match[] - 일치하는 단계
- discrepancies: Discrepancy[] - 발견된 불일치
- consistencyPercentage: number - 일치 백분율

**검증 규칙:**
- commandName은 파일 이름과 일치해야 함
- filePath는 존재해야 함
- consistencyPercentage는 (matches.length / extractedSteps.length) * 100으로 계산

### MigrationValidation (마이그레이션 검증)
**속성:**
- scenarioName: string - 예: "v1.0 to v2.5", "v2.4 to v2.5"
- initialVersion: string - 시작 버전
- targetVersion: string - 목표 버전
- setupScript: string - 초기 상태를 시뮬레이션하는 스크립트
- migrationScript: string - 마이그레이션 스크립트 경로
- executionLog: string - 전체 출력 로그
- exitCode: number - 스크립트 종료 코드
- deprecatedFilesRemoved: string[] - 제거되어야 하는 파일
- criticalFilesPresent: string[] - 마이그레이션 후 존재해야 하는 파일
- validationStatus: 'PASS' | 'FAIL' - 결과

**검증 규칙:**
- PASS이려면 exitCode가 0이어야 함
- deprecatedFilesRemoved의 모든 파일은 마이그레이션 후 존재하지 않아야 함
- criticalFilesPresent의 모든 파일은 마이그레이션 후 존재해야 함

### CrossRefValidation (교차 참조 검증)
**속성:**
- sourceFile: string - 참조를 포함하는 파일
- referenceType: 'markdown_link' | 'file_path' | 'agent_name' | 'skill_name'
- reference: string - 실제 참조 텍스트
- targetExists: boolean - 대상을 찾았는지 여부
- targetPath: string | null - 찾은 경우 해석된 경로

## 성공 기준

### 100% 일관성 목표
- 모든 명령어 문서는 구현과 100% 일치해야 함
- 모든 마이그레이션 시나리오가 성공적으로 실행되어야 함
- 모든 교차 참조가 올바르게 해석되어야 함
- 마이그레이션 후 더 이상 사용되지 않는 파일이 0개여야 함
- 마이그레이션 후 모든 중요 파일이 존재해야 함

### 자동화된 CI/CD 통합
- 검증 스크립트를 CI/CD 파이프라인에서 실행 가능
- 상세 보고서와 함께 명확한 통과/실패 상태
- 기계 판독 가능한 출력 (JSON 형식)
- 빠른 검토를 위한 사람이 읽을 수 있는 요약

### 성능
- 전체 검증 스위트가 5분 이내에 완료
- 개별 명령어 검증이 10초 이내
- 마이그레이션 시나리오 시뮬레이션이 각각 1분 이내

## 가정 및 제약사항

**가정:**
- Bash 스크립트가 주요 자동화 도구임
- 모든 파일이 표준 프로젝트 구조에서 접근 가능함
- 버전 시뮬레이션을 위해 Git 저장소를 사용할 수 있음
- 테스트 환경 생성을 위한 충분한 디스크 공간이 있음

**제약사항:**
- 라이브러리: Bash, sed, grep, diff를 스크립트 구현에 사용
- 패턴: 기존 검증 함수 재사용 (health_check, validate_installation, verify_installation)
- 표준 Unix 유틸리티 외의 외부 종속성 없음
- macOS와 Linux 모두에서 작동해야 함

## 미해결 질문 (명확화됨)

### 핵심 경로 ✅ 해결됨
1. ✅ 현재 설치에 영향을 주지 않고 v1.0 및 v2.4 환경을 시뮬레이션하는 방법은?
   - **답변**: 임시 디렉토리 사용 (`mktemp -d`)
   - 각 시나리오마다 독립된 임시 디렉토리 생성
   - 테스트 완료 후 자동 정리

2. ✅ 검증이 파괴적이어야 하나요 (실제로 마이그레이션 실행) 아니면 비파괴적이어야 하나요 (드라이런 분석)?
   - **답변**: 비파괴적 우선, 통합 테스트 옵션 제공
   - 기본: `--dry-run` 모드로 분석만 수행
   - 옵션: `--integration` 플래그로 실제 마이그레이션 테스트

### 구현 세부사항 ✅ 해결됨
3. ✅ 문서 파싱에 어느 수준의 의미 분석이 필요한가요?
   - **답변**: 단순 패턴 매칭 (grep/sed)
   - Step 1, Step 2 등의 명시적 단계 표시자 검색
   - 코드 블록 추출 및 비교
   - 복잡한 AST 파싱 불필요

4. ✅ 시스템이 문서의 예제가 실제로 실행 가능한지 검증해야 하나요?
   - **답변**: 실행 가능으로 표시된 코드 블록만 검증
   - \`\`\`bash로 표시된 블록: 실행 가능 여부 확인
   - 의사 코드나 예시 코드: 건너뛰기

5. ✅ 버전별 문서(v2.5에만 있는 기능)를 어떻게 처리해야 하나요?
   - **답변**: 현재 버전(v2.5) 기준으로 검증
   - 버전 태그가 있는 경우 해당 버전에서만 검증

### 보고 ✅ 해결됨
6. ✅ 검증 보고서는 어떤 형식을 사용해야 하나요?
   - **답변**: JSON + Markdown 둘 다 생성
   - JSON: `.claude/cache/validation-reports/{timestamp}.json`
   - Markdown: `.claude/cache/validation-reports/{timestamp}.md`
   - 터미널: 색상 포함 요약 출력

7. ✅ 검증 결과를 영구적으로 저장해야 하나요 아니면 표시만 해야 하나요?
   - **답변**: 히스토리 추적을 위해 저장
   - 저장 위치: `.claude/cache/validation-reports/`
   - 최근 30일 보고서만 유지 (자동 정리)
