#!/bin/bash
# test-quick-check-nestjs.sh
# NestJS Quick Check 통합 테스트
#
# Usage: bash test-quick-check-nestjs.sh

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"

# Source dependencies
source "${LIB_DIR}/../common.sh"
source "${LIB_DIR}/quick-check-nestjs.sh"

# 테스트 결과
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 테스트용 임시 디렉토리
TEST_DIR=$(mktemp -d)
TEST_PROJECT="${TEST_DIR}/test-nestjs-project"

# ============================================================================
# 테스트 헬퍼
# ============================================================================

test_assert() {
  local test_name="$1"
  local command="$2"
  local expected_exit_code="${3:-0}"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -n "  Testing: $test_name ... "

  set +e
  eval "$command" > /dev/null 2>&1
  local actual_exit_code=$?
  set -e

  if [[ "$actual_exit_code" == "$expected_exit_code" ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAIL${NC} (expected: $expected_exit_code, got: $actual_exit_code)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
}

# ============================================================================
# 테스트 프로젝트 설정
# ============================================================================

setup_nestjs_project() {
  mkdir -p "$TEST_PROJECT/src"
  cd "$TEST_PROJECT"

  # NestJS 구조 생성
  mkdir -p src/{users,auth}
  mkdir -p src/users/dto
  mkdir -p src/auth/guards

  log_success "NestJS test project created: $TEST_PROJECT"
}

# ============================================================================
# 테스트 케이스 생성
# ============================================================================

# 1. Valid NestJS 파일 생성
create_valid_nestjs_files() {
  # Valid module
  cat > src/users/users.module.ts <<'EOF'
import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  controllers: [UsersController],
  providers: [UsersService],
})
export class UsersModule {}
EOF

  # Valid controller
  cat > src/users/users.controller.ts <<'EOF'
import { Controller, Get } from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  findAll() {
    return this.usersService.findAll();
  }
}
EOF

  # Valid service
  cat > src/users/users.service.ts <<'EOF'
import { Injectable } from '@nestjs/common';

@Injectable()
export class UsersService {
  findAll() {
    return [];
  }
}
EOF

  # Valid DTO
  cat > src/users/dto/create-user.dto.ts <<'EOF'
export class CreateUserDto {
  name: string;
  email: string;
}
EOF

  log_success "Valid NestJS files created"
}

# 2. Invalid NestJS 파일 생성
create_invalid_nestjs_files() {
  # Controller directly injecting Repository (violation)
  cat > src/auth/auth.controller.ts <<'EOF'
import { Controller } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

@Controller('auth')
export class AuthController {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {}
}
EOF

  # Service without @Injectable decorator (violation)
  cat > src/auth/auth.service.ts <<'EOF'
export class AuthService {
  login() {
    return 'token';
  }
}
EOF

  log_success "Invalid NestJS files created"
}

# ============================================================================
# 테스트 실행
# ============================================================================

run_tests() {
  log_info "Starting NestJS Quick Check tests..."
  echo ""

  # 프로젝트 설정
  setup_nestjs_project

  # ============================================================================
  # 1. get_nestjs_component() 테스트
  # ============================================================================

  echo -e "${BLUE}1. get_nestjs_component() Tests${NC}"

  test_assert \
    "Detects module file" \
    "[[ \"\$(get_nestjs_component 'src/users/users.module.ts')\" == \"module\" ]]" \
    0

  test_assert \
    "Detects controller file" \
    "[[ \"\$(get_nestjs_component 'src/users/users.controller.ts')\" == \"controller\" ]]" \
    0

  test_assert \
    "Detects service file" \
    "[[ \"\$(get_nestjs_component 'src/users/users.service.ts')\" == \"service\" ]]" \
    0

  test_assert \
    "Detects DTO file" \
    "[[ \"\$(get_nestjs_component 'src/users/dto/create-user.dto.ts')\" == \"dto\" ]]" \
    0

  echo ""

  # ============================================================================
  # 2. Valid Files 테스트
  # ============================================================================

  echo -e "${BLUE}2. Valid NestJS Files Tests${NC}"

  create_valid_nestjs_files

  test_assert \
    "Valid module passes validation" \
    "validate_nestjs_file 'src/users/users.module.ts'" \
    0

  test_assert \
    "Valid controller passes validation" \
    "validate_nestjs_file 'src/users/users.controller.ts'" \
    0

  test_assert \
    "Valid service passes validation" \
    "validate_nestjs_file 'src/users/users.service.ts'" \
    0

  test_assert \
    "Valid DTO passes validation" \
    "validate_nestjs_file 'src/users/dto/create-user.dto.ts'" \
    0

  echo ""

  # ============================================================================
  # 3. Invalid Files 테스트
  # ============================================================================

  echo -e "${BLUE}3. Invalid NestJS Files Tests${NC}"

  create_invalid_nestjs_files

  test_assert \
    "Controller with @InjectRepository fails" \
    "validate_nestjs_file 'src/auth/auth.controller.ts'" \
    1

  test_assert \
    "Service without @Injectable fails" \
    "validate_nestjs_file 'src/auth/auth.service.ts'" \
    1

  echo ""

  # ============================================================================
  # 테스트 결과 요약
  # ============================================================================

  echo ""
  echo "=========================================="
  echo "Test Results Summary"
  echo "=========================================="
  echo "Total tests: $TOTAL_TESTS"
  echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
  echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
  echo ""

  if [[ "$FAILED_TESTS" -eq 0 ]]; then
    log_success "All tests passed! ✅"
    return 0
  else
    log_error "$FAILED_TESTS test(s) failed"
    return 1
  fi
}

# ============================================================================
# 정리
# ============================================================================

cleanup() {
  rm -rf "$TEST_DIR"
}

trap cleanup EXIT

# ============================================================================
# 메인
# ============================================================================

main() {
  echo ""
  echo "=========================================="
  echo "NestJS Quick Check Tests"
  echo "=========================================="
  echo ""

  run_tests
  local result=$?

  if [[ "$result" -eq 0 ]]; then
    log_success "NestJS quick check tests completed successfully! 🎉"
    exit 0
  else
    log_error "NestJS quick check tests failed"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
