#!/bin/bash
# test-quick-check-ddd.sh
# DDD Architecture Quick Check 통합 테스트
#
# Usage: bash test-quick-check-ddd.sh

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
TEST_PROJECT="${TEST_DIR}/test-ddd-project"

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

setup_ddd_project() {
  mkdir -p "$TEST_PROJECT/src"
  cd "$TEST_PROJECT"

  # DDD 구조 생성 (Bounded Context 기반)
  mkdir -p src/boundedContexts/{users,orders}
  mkdir -p src/boundedContexts/users/{domain,application,infrastructure,interfaces}
  mkdir -p src/boundedContexts/orders/{domain,application,infrastructure,interfaces}
  mkdir -p src/boundedContexts/users/domain/{aggregates,entities,valueObjects,domainEvents}
  mkdir -p src/boundedContexts/orders/domain/{aggregates,entities,valueObjects,domainEvents}
  mkdir -p src/sharedKernel

  log_success "DDD test project created: $TEST_PROJECT"
}

# ============================================================================
# 테스트 케이스 생성
# ============================================================================

# 1. Valid DDD 파일 생성
create_valid_ddd_files() {
  # Valid value object (immutable)
  cat > src/boundedContexts/users/domain/valueObjects/Email.ts <<'EOF'
export class Email {
  constructor(private readonly value: string) {
    if (!value.includes('@')) {
      throw new Error('Invalid email');
    }
  }

  getValue(): string {
    return this.value;
  }

  equals(other: Email): boolean {
    return this.value === other.value;
  }
}
EOF

  # Valid entity
  cat > src/boundedContexts/users/domain/entities/User.ts <<'EOF'
import { Email } from '../valueObjects/Email';

export class User {
  constructor(
    private id: string,
    private email: Email
  ) {}

  getId(): string {
    return this.id;
  }

  changeEmail(email: Email): void {
    this.email = email;
  }
}
EOF

  # Valid aggregate
  cat > src/boundedContexts/users/domain/aggregates/UserAccount.ts <<'EOF'
import { User } from '../entities/User';
import { Email } from '../valueObjects/Email';
import { UserRegisteredEvent } from '../domainEvents/UserRegisteredEvent';

export class UserAccount {
  private events: any[] = [];

  constructor(
    private id: string,
    private user: User
  ) {}

  register(): void {
    this.events.push(new UserRegisteredEvent(this.id));
  }

  getEvents(): any[] {
    return this.events;
  }
}
EOF

  # Valid domain event (past tense)
  cat > src/boundedContexts/users/domain/domainEvents/UserRegisteredEvent.ts <<'EOF'
export class UserRegisteredEvent {
  constructor(
    public readonly userId: string,
    public readonly occurredAt: Date = new Date()
  ) {}
}
EOF

  # Valid application service
  cat > src/boundedContexts/users/application/RegisterUserService.ts <<'EOF'
import { UserAccount } from '../domain/aggregates/UserAccount';
import { User } from '../domain/entities/User';
import { Email } from '../domain/valueObjects/Email';

export class RegisterUserService {
  execute(email: string): UserAccount {
    const emailVO = new Email(email);
    const user = new User('1', emailVO);
    const account = new UserAccount('1', user);
    account.register();
    return account;
  }
}
EOF

  # Valid shared kernel
  cat > src/sharedKernel/Money.ts <<'EOF'
export class Money {
  constructor(
    public readonly amount: number,
    public readonly currency: string
  ) {}

  add(other: Money): Money {
    if (this.currency !== other.currency) {
      throw new Error('Currency mismatch');
    }
    return new Money(this.amount + other.amount, this.currency);
  }
}
EOF

  log_success "Valid DDD files created"
}

# 2. Domain layer violations
create_domain_violations() {
  # Domain importing application (금지)
  cat > src/boundedContexts/users/domain/entities/Product.ts <<'EOF'
import { RegisterUserService } from '../../application/RegisterUserService';

export class Product {
  constructor(private service: RegisterUserService) {}
}
EOF

  # Domain importing infrastructure (금지)
  cat > src/boundedContexts/users/domain/entities/Order.ts <<'EOF'
import { TypeOrmRepository } from '../../infrastructure/TypeOrmRepository';

export class Order {
  constructor(private repo: TypeOrmRepository) {}
}
EOF

  # Domain importing interfaces (금지)
  cat > src/boundedContexts/users/domain/entities/Account.ts <<'EOF'
import { UserController } from '../../interfaces/UserController';

export class Account {
  constructor(private controller: UserController) {}
}
EOF

  log_success "Domain violation files created"
}

# 3. Bounded context autonomy violations
create_bounded_context_violations() {
  # Direct dependency between bounded contexts (금지)
  cat > src/boundedContexts/orders/domain/entities/OrderItem.ts <<'EOF'
import { User } from '@/boundedContexts/users/domain/entities/User';

export class OrderItem {
  constructor(private user: User) {}
}
EOF

  log_success "Bounded context violation files created"
}

# 4. Value object immutability violations
create_value_object_violations() {
  # Value object with setter (금지)
  cat > src/boundedContexts/users/domain/valueObjects/Address.ts <<'EOF'
export class Address {
  constructor(private street: string) {}

  setStreet(street: string): void {
    this.street = street;
  }
}
EOF

  # Value object with field mutation (금지)
  cat > src/boundedContexts/orders/domain/valueObjects/Price.ts <<'EOF'
export class Price {
  public amount: number;

  constructor(amount: number) {
    this.amount = amount;
  }

  increase(): void {
    this.amount += 10;
  }
}
EOF

  log_success "Value object violation files created"
}

# 5. Domain event naming violations
create_domain_event_violations() {
  # Domain event not in past tense (should be UserRegisteredEvent)
  cat > src/boundedContexts/users/domain/domainEvents/RegisterUserEvent.ts <<'EOF'
export class RegisterUserEvent {
  constructor(public userId: string) {}
}
EOF

  # Domain event without Event suffix
  cat > src/boundedContexts/orders/domain/domainEvents/OrderCreated.ts <<'EOF'
export class OrderCreated {
  constructor(public orderId: string) {}
}
EOF

  log_success "Domain event violation files created"
}

# 6. Aggregate rules violations
create_aggregate_violations() {
  # Aggregate with nested aggregate (금지)
  cat > src/boundedContexts/orders/domain/aggregates/OrderAggregate.ts <<'EOF'
import { UserAccount } from '@/boundedContexts/users/domain/aggregates/UserAccount';

export class OrderAggregate {
  constructor(private account: UserAccount) {}
}
EOF

  log_success "Aggregate violation files created"
}

# 7. Domain purity violations
create_domain_purity_violations() {
  # Domain with framework dependency
  cat > src/boundedContexts/users/domain/entities/Payment.ts <<'EOF'
import { Entity } from 'typeorm';

@Entity()
export class Payment {
  id: string;
}
EOF

  log_success "Domain purity violation files created"
}

# ============================================================================
# 테스트 실행
# ============================================================================

run_tests() {
  log_info "Starting DDD Architecture Quick Check tests..."
  echo ""

  # Quick Check 스크립트 source
  source "${LIB_DIR}/quick-check-ddd.sh"

  # 테스트 프로젝트 설정
  setup_ddd_project

  # ============================================================================
  # 1. Valid Files Tests
  # ============================================================================

  echo -e "${BLUE}1. Valid DDD Files Tests${NC}"

  create_valid_ddd_files

  test_assert \
    "Valid value object passes" \
    "validate_ddd_file 'src/boundedContexts/users/domain/valueObjects/Email.ts'" \
    0

  test_assert \
    "Valid entity passes" \
    "validate_ddd_file 'src/boundedContexts/users/domain/entities/User.ts'" \
    0

  test_assert \
    "Valid aggregate passes" \
    "validate_ddd_file 'src/boundedContexts/users/domain/aggregates/UserAccount.ts'" \
    0

  test_assert \
    "Valid domain event passes" \
    "validate_ddd_file 'src/boundedContexts/users/domain/domainEvents/UserRegisteredEvent.ts'" \
    0

  test_assert \
    "Valid application service passes" \
    "validate_ddd_file 'src/boundedContexts/users/application/RegisterUserService.ts'" \
    0

  test_assert \
    "Valid shared kernel passes" \
    "validate_ddd_file 'src/sharedKernel/Money.ts'" \
    0

  echo ""

  # ============================================================================
  # 2. Domain Layer Violation Tests
  # ============================================================================

  echo -e "${BLUE}2. Domain Layer Violation Tests${NC}"

  create_domain_violations

  test_assert \
    "Domain importing application fails" \
    "validate_ddd_file 'src/boundedContexts/users/domain/entities/Product.ts'" \
    1

  test_assert \
    "Domain importing infrastructure fails" \
    "validate_ddd_file 'src/boundedContexts/users/domain/entities/Order.ts'" \
    1

  test_assert \
    "Domain importing interfaces fails" \
    "validate_ddd_file 'src/boundedContexts/users/domain/entities/Account.ts'" \
    1

  echo ""

  # ============================================================================
  # 3. Bounded Context Autonomy Tests
  # ============================================================================

  echo -e "${BLUE}3. Bounded Context Autonomy Tests${NC}"

  create_bounded_context_violations

  test_assert \
    "Direct bounded context dependency fails" \
    "validate_ddd_file 'src/boundedContexts/orders/domain/entities/OrderItem.ts'" \
    1

  echo ""

  # ============================================================================
  # 4. Value Object Immutability Tests
  # ============================================================================

  echo -e "${BLUE}4. Value Object Immutability Tests${NC}"

  create_value_object_violations

  test_assert \
    "Value object with setter fails" \
    "validate_ddd_file 'src/boundedContexts/users/domain/valueObjects/Address.ts'" \
    1

  test_assert \
    "Value object with field mutation fails" \
    "validate_ddd_file 'src/boundedContexts/orders/domain/valueObjects/Price.ts'" \
    1

  echo ""

  # ============================================================================
  # 5. Domain Event Naming Tests
  # ============================================================================

  echo -e "${BLUE}5. Domain Event Naming Tests${NC}"

  create_domain_event_violations

  test_assert \
    "Domain event not in past tense shows warnings but passes" \
    "validate_ddd_file 'src/boundedContexts/users/domain/domainEvents/RegisterUserEvent.ts'" \
    0

  test_assert \
    "Domain event without Event suffix shows warnings but passes" \
    "validate_ddd_file 'src/boundedContexts/orders/domain/domainEvents/OrderCreated.ts'" \
    0

  echo ""

  # ============================================================================
  # 6. Aggregate Rules Tests
  # ============================================================================

  echo -e "${BLUE}6. Aggregate Rules Tests${NC}"

  create_aggregate_violations

  test_assert \
    "Aggregate with nested aggregate fails" \
    "validate_ddd_file 'src/boundedContexts/orders/domain/aggregates/OrderAggregate.ts'" \
    1

  echo ""

  # ============================================================================
  # 7. Domain Purity Tests
  # ============================================================================

  echo -e "${BLUE}7. Domain Purity Tests${NC}"

  create_domain_purity_violations

  test_assert \
    "Domain with framework dependency fails" \
    "validate_ddd_file 'src/boundedContexts/users/domain/entities/Payment.ts'" \
    1

  echo ""

  # ============================================================================
  # 8. Shared Kernel Tests
  # ============================================================================

  echo -e "${BLUE}8. Shared Kernel Tests${NC}"

  # Shared kernel can be imported by any bounded context
  cat > src/boundedContexts/orders/domain/valueObjects/OrderPrice.ts <<'EOF'
import { Money } from '@/sharedKernel/Money';

export class OrderPrice {
  constructor(private total: Money) {}

  getTotal(): Money {
    return this.total;
  }
}
EOF

  test_assert \
    "Bounded context importing shared kernel passes" \
    "validate_ddd_file 'src/boundedContexts/orders/domain/valueObjects/OrderPrice.ts'" \
    0

  echo ""

  # ============================================================================
  # 9. Type-only Import Tests (ACL pattern)
  # ============================================================================

  echo -e "${BLUE}9. Type-only Import Tests (ACL Pattern)${NC}"

  # Type-only imports allow bounded context references (ACL pattern)
  cat > src/boundedContexts/orders/domain/entities/CustomerReference.ts <<'EOF'
import type { User } from '@/boundedContexts/users/domain/entities/User';

export class CustomerReference {
  userId?: string;
  user?: User;  // Type reference only
}
EOF

  test_assert \
    "Type-only import between bounded contexts passes" \
    "validate_ddd_file 'src/boundedContexts/orders/domain/entities/CustomerReference.ts'" \
    0

  echo ""

  # ============================================================================
  # 10. Directory Validation Tests
  # ============================================================================

  echo -e "${BLUE}10. Directory Validation Tests${NC}"

  test_assert \
    "Directory validation detects violations" \
    "validate_ddd_directory 'src'" \
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
  echo "DDD Architecture Quick Check Tests"
  echo "=========================================="
  echo ""

  run_tests
  local result=$?

  if [[ "$result" -eq 0 ]]; then
    log_success "DDD Architecture Quick Check tests completed successfully! 🎉"
    exit 0
  else
    log_error "DDD Architecture Quick Check tests failed"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
