# Architecture Compliance Check

자동화된 아키텍처 패턴 검증 시스템. FSD (Feature-Sliced Design), Clean Architecture, Hexagonal Architecture 패턴을 자동으로 검증합니다.

## Features

- ✅ **Multi-Architecture Support**: FSD, Clean, Hexagonal 아키텍처 자동 감지 및 검증
- ✅ **Layer Rule Validation**: 레이어 간 의존성 방향 검증
- ✅ **Circular Dependency Detection**: DFS 알고리즘을 통한 순환 의존성 감지
- ✅ **Naming Convention Check**: 파일 및 컴포넌트 네이밍 규칙 검증
- ✅ **Detailed Reports**: 위반 사항에 대한 상세한 보고서 및 수정 제안

## Usage

### Quick Start

```bash
# Run architecture validation
bash .claude/lib/check-architecture-compliance.sh
```

### Direct TypeScript Execution

```bash
# Using tsx (recommended)
tsx .claude/architectures/tools/validate.ts

# Using ts-node
ts-node .claude/architectures/tools/validate.ts

# Using Node.js with loader
node --loader ts-node/esm .claude/architectures/tools/validate.ts
```

## Configuration

Create `.claude/architectures/config.json` to customize validation:

```json
{
  "architectureType": "fsd",
  "strictnessLevel": "moderate",
  "enabledRules": [],
  "disabledRules": [],
  "ignorePatterns": [
    "**/node_modules/**",
    "**/*.test.ts",
    "**/*.test.tsx",
    "**/__tests__/**"
  ]
}
```

### Configuration Options

- **architectureType**: `"fsd" | "clean" | "hexagonal" | "auto"`
  - `auto`: Automatically detect architecture type
  - `fsd`: Validate Feature-Sliced Design pattern
  - `clean`: Validate Clean Architecture pattern
  - `hexagonal`: Validate Hexagonal (Ports & Adapters) pattern

- **strictnessLevel**: `"strict" | "moderate" | "lenient"`
  - `strict`: All warnings treated as errors
  - `moderate`: Standard validation (default)
  - `lenient`: Only critical errors reported

- **enabledRules**: Array of rule IDs to enable (empty = all enabled)
- **disabledRules**: Array of rule IDs to disable
- **ignorePatterns**: Glob patterns for files to ignore

## Validation Rules

### FSD (Feature-Sliced Design)

- **fsd-layer-no-upward-import**: Lower layers cannot import from higher layers
  - Layer order: `app` → `processes` → `pages` → `widgets` → `features` → `entities` → `shared`
  - Example violation: `features/` importing from `pages/`

- **fsd-naming-convention**: Enforce naming conventions
  - Hooks: `use{Name}.ts` (e.g., `useAuth.ts`)
  - Stores: `{entity}Store.ts` (e.g., `userStore.ts`)

### Clean Architecture

- **clean-dependency-direction**: Dependencies point inward only
  - Layer order: `domain` ← `application` ← `infrastructure`/`presentation`
  - Domain layer cannot depend on any other layer

- **clean-usecase-isolation**: Use cases must be in application layer
  - Files containing "UseCase" should be in `application/` directory

### Hexagonal Architecture

- **hexagonal-ports-separation**: Core cannot depend on Adapters
  - Core (domain + ports) defines interfaces
  - Adapters implement those interfaces
  - Dependencies: Adapters → Core (never Core → Adapters)

- **hexagonal-port-interface**: Port interfaces in correct location
  - Files containing "Port" should be in `ports/` directory

### Common Rules

- **circular-dependency**: Detect import cycles
  - Uses DFS algorithm to find circular dependencies
  - Reports complete cycle path

## Output

### Success

```
🏗️  Architecture Compliance Check...
✅ Validating 127 files...
🔄 Checking for circular dependencies...
✅ No circular dependencies found

================================================================================
✅ All checks passed! (2.3s)
📊 127 files checked
================================================================================
📁 Report saved to: .claude/cache/validation-reports/latest.json
```

### Failure

```
🏗️  Architecture Compliance Check...
✅ Validating 127 files...
🔄 Checking for circular dependencies...

================================================================================
❌ Validation failed! (2.5s)
📊 127 files checked

🔴 Errors (3):

1. src/features/auth/index.ts:5
   [fsd-layer-no-upward-import] features 레이어는 pages 레이어를 import할 수 없습니다
   💡 pages의 기능을 shared 레이어로 이동하거나 의존성 역전 패턴을 적용하세요

2. src/features/auth/hooks/auth.ts:1
   [fsd-naming-convention] Hook 파일은 use{Name}.ts 형식이어야 합니다
   💡 파일명을 camelCase로 변경하세요 (예: useUserAuth.ts)

3. src/entities/user/index.ts:3
   [circular-dependency] Circular dependency detected: user → profile → user
   💡 Refactor to remove circular dependency by extracting shared code

================================================================================
```

## Reports

Validation reports are saved to `.claude/cache/validation-reports/`:

- `latest.json`: Most recent validation result
- `architecture-{timestamp}.json`: Historical reports

### Report Structure

```json
{
  "valid": false,
  "errors": [
    {
      "file": "src/features/auth/index.ts",
      "line": 5,
      "rule": "fsd-layer-no-upward-import",
      "severity": "error",
      "message": "features 레이어는 pages 레이어를 import할 수 없습니다",
      "suggestion": "pages의 기능을 shared 레이어로 이동하세요"
    }
  ],
  "warnings": [],
  "suggestions": [],
  "checkedFiles": ["src/features/auth/index.ts"],
  "timestamp": "2025-01-13T12:00:00.000Z",
  "duration": "2.3s",
  "architectureType": "fsd"
}
```

## Integration

### Major Workflow

Architecture validation is automatically integrated into the Major workflow at **Step 13.7**.

When implementing a new feature:

1. Complete implementation (Steps 1-13)
2. **Step 13.7**: Architecture validation runs automatically
3. If violations found, choose to:
   - Fix violations and re-run
   - Continue with warnings (not recommended)
   - Abort implementation

### Epic Workflow

For Epic-level projects, architecture validation is included in the completion checklist:

```markdown
🎯 Epic 완료 기준:
- [ ] 모든 Feature 완료
- [ ] 모든 Feature 테스트 통과
- [ ] **아키텍처 검증 통과**
- [ ] 통합 테스트 통과
```

## Development

### Project Structure

```
.claude/architectures/
├── tools/
│   ├── validate.ts           # Main CLI entry point
│   ├── config-loader.ts      # Configuration management
│   ├── file-collector.ts     # File collection utilities
│   ├── import-parser.ts      # Import statement parser
│   ├── dependency-graph.ts   # Dependency graph builder
│   ├── cycle-detector.ts     # Circular dependency detection
│   ├── rule-engine.ts        # Rule execution engine
│   ├── result-saver.ts       # Result persistence
│   └── rules/
│       ├── fsd-rules.ts      # FSD architecture rules
│       ├── clean-rules.ts    # Clean Architecture rules
│       └── hexagonal-rules.ts # Hexagonal rules
├── types/
│   └── validation-types.ts   # Type definitions
└── __tests__/
    ├── validate.test.ts      # Unit tests
    ├── fsd-rules.test.ts     # FSD rule tests
    ├── cycle-detector.test.ts # Cycle detection tests
    ├── integration.test.ts   # Integration tests
    └── performance.test.ts   # Performance tests
```

### Running Tests

```bash
# Run all tests
vitest

# Run specific test file
vitest .claude/architectures/__tests__/validate.test.ts

# Run with coverage
vitest --coverage
```

### Type Checking

```bash
# Check TypeScript types
tsc --noEmit --project .claude/architectures/tsconfig.json
```

## Troubleshooting

### "No TypeScript execution environment found"

Install one of the following:

```bash
# Option 1: tsx (fastest, recommended)
npm install -g tsx

# Option 2: ts-node
npm install -g ts-node

# Option 3: TypeScript compiler
npm install -g typescript
```

### "Validation script not found"

Ensure you're running from the project root:

```bash
cd $(git rev-parse --show-toplevel)
bash .claude/lib/check-architecture-compliance.sh
```

### Performance Issues

For large codebases, consider:

1. Add more ignore patterns in config
2. Increase `maxFiles` limit
3. Run validation on changed files only

## Contributing

When adding new rules:

1. Create test file in `__tests__/` (TDD)
2. Implement rule in `tools/rules/`
3. Register rule in `tools/validate.ts`
4. Update this README

## License

Part of Claude Workflow System - MIT License
