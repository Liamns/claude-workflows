#!/bin/bash
# validation-config.sh
# Validation System Configuration
# 이 파일을 수정하여 검증 임계값 및 동작 변경 가능

# =============================================================================
# 문서 검증 임계값
# =============================================================================

# 문서 일치율 PASS 임계값 (%)
readonly VALIDATION_DOC_THRESHOLD_PASS=90

# 문서 일치율 WARNING 임계값 (%)
readonly VALIDATION_DOC_THRESHOLD_WARNING=70

# =============================================================================
# 일관성 점수 임계값
# =============================================================================

# 전체 일관성 점수 PASS 임계값 (%)
readonly VALIDATION_CONSISTENCY_THRESHOLD_PASS=90

# 전체 일관성 점수 WARNING 임계값 (%)
readonly VALIDATION_CONSISTENCY_THRESHOLD_WARNING=70

# =============================================================================
# 보고서 관리
# =============================================================================

# 보고서 보존 기간 (일)
readonly VALIDATION_REPORT_RETENTION_DAYS=30

# =============================================================================
# 타임아웃 설정
# =============================================================================

# 전체 검증 타임아웃 (초)
readonly VALIDATION_TIMEOUT_SECONDS=300

# =============================================================================
# 기능 플래그
# =============================================================================

# 병렬 실행 기본값
readonly VALIDATION_PARALLEL_DEFAULT=false

# jq 필수 여부 (true: jq 없으면 실패, false: jq 없어도 계속)
readonly VALIDATION_REQUIRE_JQ=false

# =============================================================================
# 점수 계산 가중치
# =============================================================================

# 문서 일치율 계산 가중치
readonly VALIDATION_SCORE_FILE_EXISTS=10      # 파일 존재
readonly VALIDATION_SCORE_STEP_EXISTS=30      # Step 섹션 존재
readonly VALIDATION_SCORE_CODE_EXISTS=30      # 코드 블록 존재
readonly VALIDATION_SCORE_BALANCE=30          # Step-코드 균형

# =============================================================================
# 디버그 및 로깅
# =============================================================================

# 디버그 모드 (true: 상세 로그)
readonly VALIDATION_DEBUG=${VALIDATION_DEBUG:-false}

# 로그 레벨 (ERROR, WARNING, INFO, DEBUG)
readonly VALIDATION_LOG_LEVEL=${VALIDATION_LOG_LEVEL:-INFO}
