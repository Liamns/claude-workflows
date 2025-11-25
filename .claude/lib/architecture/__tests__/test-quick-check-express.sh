#!/bin/bash
# test-quick-check-express.sh
# Express MVC Quick Check 통합 테스트
#
# Usage: bash test-quick-check-express.sh

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"

# Source dependencies
source "${LIB_DIR}/../common.sh"
source "${LIB_DIR}/quick-check-express.sh"

# 테스트 결과
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 테스트용 임시 디렉토리
TEST_DIR=$(mktemp -d)
TEST_PROJECT="${TEST_DIR}/test-express-project"

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

setup_express_project() {
  mkdir -p "$TEST_PROJECT/src"
  cd "$TEST_PROJECT"

  # Express MVC 구조 생성
  mkdir -p src/{routes,controllers,services,models,middlewares,utils}

  log_success "Express test project created: $TEST_PROJECT"
}

# ============================================================================
# 테스트 케이스 생성
# ============================================================================

# 1. Valid Express 파일 생성
create_valid_express_files() {
  # Valid route
  cat > src/routes/users.routes.ts <<'EOF'
import { Router } from 'express';
import { UsersController } from '../controllers/users.controller';

const router = Router();
const usersController = new UsersController();

router.get('/', usersController.getAll);
router.post('/', usersController.create);

export default router;
EOF

  # Valid controller
  cat > src/controllers/users.controller.ts <<'EOF'
import { Request, Response } from 'express';
import { UsersService } from '../services/users.service';

export class UsersController {
  private usersService = new UsersService();

  getAll = (req: Request, res: Response) => {
    const users = this.usersService.findAll();
    res.json(users);
  };

  create = (req: Request, res: Response) => {
    const user = this.usersService.create(req.body);
    res.status(201).json(user);
  };
}
EOF

  # Valid service
  cat > src/services/users.service.ts <<'EOF'
export class UsersService {
  findAll() {
    return [];
  }

  create(data: any) {
    return { id: 1, ...data };
  }
}
EOF

  # Valid model
  cat > src/models/user.model.ts <<'EOF'
export interface User {
  id: number;
  name: string;
  email: string;
}
EOF

  # Valid middleware
  cat > src/middlewares/auth.middleware.ts <<'EOF'
import { Request, Response, NextFunction } from 'express';

export const authMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const token = req.headers.authorization;
  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
};
EOF

  log_success "Valid Express files created"
}

# 2. Invalid Express 파일 생성
create_invalid_express_files() {
  # Route with business logic (violation)
  cat > src/routes/bad-route.ts <<'EOF'
import { Router } from 'express';

const router = Router();

router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  // Business logic in route - VIOLATION
  const user = await User.findOne({ email });
  if (!user || user.password !== password) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  res.json({ token: 'xyz' });
});

export default router;
EOF

  # Middleware in wrong location (violation)
  cat > src/utils/bad-middleware.ts <<'EOF'
import { Request, Response, NextFunction } from 'express';

export const badMiddleware = (req: Request, res: Response, next: NextFunction) => {
  next();
};
EOF

  log_success "Invalid Express files created"
}

# ============================================================================
# 테스트 실행
# ============================================================================

run_tests() {
  log_info "Starting Express MVC Quick Check tests..."
  echo ""

  # 프로젝트 설정
  setup_express_project

  # ============================================================================
  # 1. get_express_component() 테스트
  # ============================================================================

  echo -e "${BLUE}1. get_express_component() Tests${NC}"

  test_assert \
    "Detects route file" \
    "[[ \"\$(get_express_component 'src/routes/users.routes.ts')\" == \"route\" ]]" \
    0

  test_assert \
    "Detects controller file" \
    "[[ \"\$(get_express_component 'src/controllers/users.controller.ts')\" == \"controller\" ]]" \
    0

  test_assert \
    "Detects service file" \
    "[[ \"\$(get_express_component 'src/services/users.service.ts')\" == \"service\" ]]" \
    0

  test_assert \
    "Detects model file" \
    "[[ \"\$(get_express_component 'src/models/user.model.ts')\" == \"model\" ]]" \
    0

  test_assert \
    "Detects middleware file" \
    "[[ \"\$(get_express_component 'src/middlewares/auth.middleware.ts')\" == \"middleware\" ]]" \
    0

  echo ""

  # ============================================================================
  # 2. Valid Files 테스트
  # ============================================================================

  echo -e "${BLUE}2. Valid Express Files Tests${NC}"

  create_valid_express_files

  test_assert \
    "Valid route passes validation" \
    "validate_express_file 'src/routes/users.routes.ts'" \
    0

  test_assert \
    "Valid controller passes validation" \
    "validate_express_file 'src/controllers/users.controller.ts'" \
    0

  test_assert \
    "Valid service passes validation" \
    "validate_express_file 'src/services/users.service.ts'" \
    0

  test_assert \
    "Valid model passes validation" \
    "validate_express_file 'src/models/user.model.ts'" \
    0

  test_assert \
    "Valid middleware passes validation" \
    "validate_express_file 'src/middlewares/auth.middleware.ts'" \
    0

  echo ""

  # ============================================================================
  # 3. Invalid Files 테스트
  # ============================================================================

  echo -e "${BLUE}3. Invalid Express Files Tests${NC}"

  create_invalid_express_files

  test_assert \
    "Route with business logic fails" \
    "validate_express_file 'src/routes/bad-route.ts'" \
    1

  test_assert \
    "Middleware in wrong location fails" \
    "validate_express_file 'src/utils/bad-middleware.ts'" \
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
  echo "Express MVC Quick Check Tests"
  echo "=========================================="
  echo ""

  run_tests
  local result=$?

  if [[ "$result" -eq 0 ]]; then
    log_success "Express quick check tests completed successfully! 🎉"
    exit 0
  else
    log_error "Express quick check tests failed"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
