#!/bin/bash
# test-quick-check-serverless.sh
# Serverless Architecture Quick Check 통합 테스트
#
# Usage: bash test-quick-check-serverless.sh

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"

# Source dependencies
source "${LIB_DIR}/../common.sh"

# 테스트 결과
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 테스트용 임시 디렉토리
TEST_DIR=$(mktemp -d)
TEST_PROJECT="${TEST_DIR}/test-serverless-project"

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

setup_serverless_project() {
  mkdir -p "$TEST_PROJECT/src"
  cd "$TEST_PROJECT"

  # Serverless 구조 생성
  mkdir -p src/{functions,layers,events,shared}
  mkdir -p src/functions/{api,stream,scheduled}
  mkdir -p src/layers/common
  mkdir -p src/events/schemas

  log_success "Serverless test project created: $TEST_PROJECT"
}

# ============================================================================
# 테스트 케이스 생성
# ============================================================================

# 1. Valid Serverless 파일 생성
create_valid_serverless_files() {
  # Valid function (stateless)
  cat > src/functions/api/createUser.ts <<'EOF'
import { APIGatewayProxyHandler } from 'aws-lambda';
import { UserService } from '@/layers/common/services/UserService';

export const handler: APIGatewayProxyHandler = async (event) => {
  try {
    const body = JSON.parse(event.body || '{}');
    const service = new UserService();
    const user = await service.createUser(body);

    return {
      statusCode: 200,
      body: JSON.stringify(user)
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal Server Error' })
    };
  }
};
EOF

  # Valid layer
  cat > src/layers/common/services/UserService.ts <<'EOF'
import { DynamoDB } from 'aws-sdk';

export class UserService {
  private dynamodb = new DynamoDB.DocumentClient();

  async createUser(data: any) {
    await this.dynamodb.put({
      TableName: process.env.USERS_TABLE!,
      Item: data
    }).promise();

    return data;
  }
}
EOF

  # Valid event schema
  cat > src/events/schemas/UserCreated.ts <<'EOF'
export interface UserCreatedEvent {
  userId: string;
  email: string;
  timestamp: number;
}
EOF

  # Valid shared utility
  cat > src/shared/utils/formatters.ts <<'EOF'
export const formatDate = (date: Date): string => {
  return date.toISOString();
};

export const formatCurrency = (amount: number): string => {
  return `$${amount.toFixed(2)}`;
};
EOF

  log_success "Valid Serverless files created"
}

# 2. Dependency violation 파일 생성
create_dependency_violations() {
  # Layers importing functions (금지)
  cat > src/layers/common/helpers/FunctionHelper.ts <<'EOF'
import { handler } from '@/functions/api/createUser';

export const callFunction = () => {
  return handler;
};
EOF

  # Shared importing functions (금지)
  cat > src/shared/utils/helpers.ts <<'EOF'
import { handler } from '@/functions/api/createUser';

export const getHandler = () => handler;
EOF

  # Events importing functions (금지)
  cat > src/events/schemas/OrderEvent.ts <<'EOF'
import { handler } from '@/functions/api/createUser';

export interface OrderEvent {
  handler: typeof handler;
}
EOF

  log_success "Dependency violation files created"
}

# 3. Stateful pattern violations
create_stateful_violations() {
  # Global state in function
  cat > src/functions/api/getUser.ts <<'EOF'
import { APIGatewayProxyHandler } from 'aws-lambda';

let cache: any = {};  // Stateful!

export const handler: APIGatewayProxyHandler = async (event) => {
  const id = event.pathParameters?.id;

  if (cache[id]) {
    return {
      statusCode: 200,
      body: JSON.stringify(cache[id])
    };
  }

  cache[id] = { id, name: 'Test' };

  return {
    statusCode: 200,
    body: JSON.stringify(cache[id])
  };
};
EOF

  log_success "Stateful violation files created"
}

# 4. Cold start violations
create_cold_start_violations() {
  # Too many imports
  cat > src/functions/api/heavyFunction.ts <<'EOF'
import { APIGatewayProxyHandler } from 'aws-lambda';
import { DynamoDB } from 'aws-sdk';
import { S3 } from 'aws-sdk';
import { SQS } from 'aws-sdk';
import { SNS } from 'aws-sdk';
import { Lambda } from 'aws-sdk';
import { CloudWatch } from 'aws-sdk';
import { EventBridge } from 'aws-sdk';
import { Kinesis } from 'aws-sdk';
import { Firehose } from 'aws-sdk';
import { StepFunctions } from 'aws-sdk';
import { SecretsManager } from 'aws-sdk';
import { SSM } from 'aws-sdk';
import { CloudFormation } from 'aws-sdk';
import { EC2 } from 'aws-sdk';
import { RDS } from 'aws-sdk';
import { ECS } from 'aws-sdk';
import { EKS } from 'aws-sdk';
import { IAM } from 'aws-sdk';
import { KMS } from 'aws-sdk';
import { CloudFront } from 'aws-sdk';
import { Route53 } from 'aws-sdk';

export const handler: APIGatewayProxyHandler = async (event) => {
  return {
    statusCode: 200,
    body: JSON.stringify({ message: 'Heavy function' })
  };
};
EOF

  log_success "Cold start violation files created"
}

# 5. Timeout awareness violations
create_timeout_violations() {
  # Infinite loop
  cat > src/functions/stream/processor.ts <<'EOF'
import { DynamoDBStreamHandler } from 'aws-lambda';

export const handler: DynamoDBStreamHandler = async (event) => {
  while (true) {
    // Poll for messages (anti-pattern in serverless)
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
};
EOF

  # Sleep/delay pattern
  cat > src/functions/scheduled/cleaner.ts <<'EOF'
import { ScheduledHandler } from 'aws-lambda';

export const handler: ScheduledHandler = async (event) => {
  for (let i = 0; i < 100; i++) {
    await new Promise(resolve => setTimeout(resolve, 5000));
    console.log('Processing batch', i);
  }
};
EOF

  log_success "Timeout violation files created"
}

# ============================================================================
# 테스트 실행
# ============================================================================

run_tests() {
  log_info "Starting Serverless Architecture Quick Check tests..."
  echo ""

  # Quick Check 스크립트 source
  source "${LIB_DIR}/quick-check-serverless.sh"

  # 테스트 프로젝트 설정
  setup_serverless_project

  # ============================================================================
  # 1. Valid Files Tests
  # ============================================================================

  echo -e "${BLUE}1. Valid Serverless Files Tests${NC}"

  create_valid_serverless_files

  test_assert \
    "Valid function passes" \
    "validate_serverless_file 'src/functions/api/createUser.ts'" \
    0

  test_assert \
    "Valid layer passes" \
    "validate_serverless_file 'src/layers/common/services/UserService.ts'" \
    0

  test_assert \
    "Valid event schema passes" \
    "validate_serverless_file 'src/events/schemas/UserCreated.ts'" \
    0

  test_assert \
    "Valid shared utility passes" \
    "validate_serverless_file 'src/shared/utils/formatters.ts'" \
    0

  echo ""

  # ============================================================================
  # 2. Dependency Violation Tests
  # ============================================================================

  echo -e "${BLUE}2. Dependency Violation Tests${NC}"

  create_dependency_violations

  test_assert \
    "Layers importing functions fails" \
    "validate_serverless_file 'src/layers/common/helpers/FunctionHelper.ts'" \
    1

  test_assert \
    "Shared importing functions fails" \
    "validate_serverless_file 'src/shared/utils/helpers.ts'" \
    1

  test_assert \
    "Events importing functions fails" \
    "validate_serverless_file 'src/events/schemas/OrderEvent.ts'" \
    1

  echo ""

  # ============================================================================
  # 3. Stateless Tests (warnings)
  # ============================================================================

  echo -e "${BLUE}3. Stateless Tests (warnings)${NC}"

  create_stateful_violations

  test_assert \
    "Function with global state shows warnings but passes" \
    "validate_serverless_file 'src/functions/api/getUser.ts'" \
    0

  echo ""

  # ============================================================================
  # 4. Cold Start Tests (warnings)
  # ============================================================================

  echo -e "${BLUE}4. Cold Start Tests (warnings)${NC}"

  create_cold_start_violations

  test_assert \
    "Function with many imports shows warnings but passes" \
    "validate_serverless_file 'src/functions/api/heavyFunction.ts'" \
    0

  echo ""

  # ============================================================================
  # 5. Timeout Awareness Tests (warnings)
  # ============================================================================

  echo -e "${BLUE}5. Timeout Awareness Tests (warnings)${NC}"

  create_timeout_violations

  test_assert \
    "Function with infinite loop shows warnings but passes" \
    "validate_serverless_file 'src/functions/stream/processor.ts'" \
    0

  test_assert \
    "Function with delays shows warnings but passes" \
    "validate_serverless_file 'src/functions/scheduled/cleaner.ts'" \
    0

  echo ""

  # ============================================================================
  # 6. Valid Dependencies Tests
  # ============================================================================

  echo -e "${BLUE}6. Valid Dependencies Tests${NC}"

  # Functions can import layers, shared, events
  cat > src/functions/api/orderHandler.ts <<'EOF'
import { UserService } from '@/layers/common/services/UserService';
import { formatDate } from '@/shared/utils/formatters';
import type { UserCreatedEvent } from '@/events/schemas/UserCreated';

export const handler = async () => {
  const service = new UserService();
  const date = formatDate(new Date());
  const event: UserCreatedEvent = {
    userId: '1',
    email: 'test@example.com',
    timestamp: Date.now()
  };
  return { statusCode: 200, body: JSON.stringify(event) };
};
EOF

  test_assert \
    "Function importing layers/shared/events passes" \
    "validate_serverless_file 'src/functions/api/orderHandler.ts'" \
    0

  # Layers can import shared
  cat > src/layers/common/services/OrderService.ts <<'EOF'
import { formatDate } from '@/shared/utils/formatters';

export class OrderService {
  getFormattedDate() {
    return formatDate(new Date());
  }
}
EOF

  test_assert \
    "Layer importing shared passes" \
    "validate_serverless_file 'src/layers/common/services/OrderService.ts'" \
    0

  echo ""

  # ============================================================================
  # 7. Directory Validation Tests
  # ============================================================================

  echo -e "${BLUE}7. Directory Validation Tests${NC}"

  test_assert \
    "Directory validation detects violations" \
    "validate_serverless_directory 'src'" \
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
  echo "Serverless Architecture Quick Check Tests"
  echo "=========================================="
  echo ""

  run_tests
  local result=$?

  if [[ "$result" -eq 0 ]]; then
    log_success "Serverless Architecture Quick Check tests completed successfully! 🎉"
    exit 0
  else
    log_error "Serverless Architecture Quick Check tests failed"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
