# Examples

Real-world usage examples of Claude Workflows across different project types and scenarios.

## 📱 React + TypeScript Projects

### Example 1: E-commerce Product Listing

#### Scenario
Adding a product filtering feature to an existing e-commerce site.

```bash
# Initial request
/triage "Add product filtering by price, category, and brand"

# Output
🔍 Analyzing task complexity...
✅ Major workflow selected (new feature with multiple components)

# Execution
/major product-filtering
```

#### Result
- Specification created with clear requirements
- Component structure following FSD architecture
- Full test coverage (85%)
- API integration with React Query
- Type-safe filtering logic

### Example 2: Authentication Bug Fix

#### Scenario
Users report being logged out randomly.

```bash
# Quick analysis
/triage "Users getting logged out randomly, probably token refresh issue"

# Output
🔍 Analyzing task complexity...
✅ Minor workflow selected (bug fix in existing feature)

# Execution
/minor fix-token-refresh
```

#### Result
- Root cause identified: Race condition in token refresh
- `httpClient` interceptor updated
- Added retry logic with exponential backoff
- Test case added to prevent regression

### Example 3: UI Polish

#### Scenario
Update button colors to match new design system.

```bash
/micro update button colors to match Figma designs

# Or with triage
/triage "change button colors"
→ Micro workflow (CSS-only change)
```

#### Result
- CSS variables updated
- No logic changes
- Completed in under 2 minutes

## 🎨 Vue.js Projects

### Example: Vuex to Pinia Migration

```bash
/triage "Migrate store from Vuex to Pinia"

# Major workflow selected
/major vuex-to-pinia-migration
```

#### Process Flow
1. **Specification**: Migration strategy documented
2. **Plan**: Phased migration approach
3. **Tasks**: Store-by-store migration tasks
4. **Implementation**: Automated with codemods
5. **Testing**: E2E tests ensure functionality

## 🐍 Python/Django Projects

### Example: REST API Endpoint

```bash
/triage "Add user profile API endpoint with CRUD operations"

# Major workflow with api-designer agent
/major user-profile-api
```

#### Generated Structure
```
api/
├── views/
│   └── user_profile.py      # ViewSet with CRUD
├── serializers/
│   └── user_profile.py      # DRF Serializer
├── tests/
│   └── test_user_profile.py # Full test suite
└── urls.py                   # URL configuration
```

## 📱 Mobile (Capacitor) Projects

### Example: Platform-Specific Feature

```bash
/triage "Add biometric authentication for mobile app"

# Major workflow with mobile-specialist
/major biometric-auth
```

#### Implementation
- Platform detection for iOS/Android/Web
- Native API integration via Capacitor
- Fallback for web platform
- Proper permission handling

## 🔄 Git Workflow Examples

### Smart Commits

#### Scenario 1: After Feature Development

```bash
# After implementing a feature
/commit

# Analyzes changes and generates:
feat(user): add profile picture upload functionality

- Implemented image upload with drag-and-drop
- Added file size and type validation
- Integrated with S3 for storage
- Updated user model with avatar_url field

Closes #123
```

#### Scenario 2: Multiple Changes

```bash
/commit

# Detects multiple change types:
🔍 Multiple change types detected:
- Feature: 3 files
- Bug fix: 1 file
- Docs: 2 files

How to handle?
[1] Separate commits (recommended)
[2] Single commit with primary type
[3] Manual selection

> 1

# Creates three separate commits
```

### PR 생성

#### Example 1: 기본 사용법

```bash
# Feature 브랜치에서 작업 완료 후
/pr

# 자동으로 수행되는 작업:
# 1. 현재 브랜치와 main 브랜치 비교
# 2. 커밋 히스토리 분석
# 3. 변경된 파일 분석
# 4. PR 템플릿 자동 완성
# 5. GitHub PR 생성
```

#### Example 2: Dry-run 모드

```bash
# PR을 생성하지 않고 템플릿만 확인
/pr --dry-run

# 출력 예시:
🔍 현재 브랜치 분석 중...
  ✓ 브랜치: feature/auth-improvement
  ✓ 베이스: main
  ✓ 커밋 수: 5개

📊 변경사항 분석 중...
  ✓ feat: 2개
  ✓ fix: 1개
  ✓ test: 2개

✍️ PR 템플릿 자동 완성 중...
  ✓ 변경사항 섹션 (3개 체크)
  ✓ 작업 내용 자동 생성
  ✓ 참고 자료 (이슈 링크)

[생성된 PR 템플릿 미리보기]
```

#### Example 3: 플래그 옵션 활용

```bash
# Draft PR로 생성
/pr --draft

# 검증 후 PR 생성 (타입 체크 + 테스트)
/pr --validate

# PR 생성 후 자동 리뷰까지 수행
/pr --review

# 베이스 브랜치 지정
/pr --base develop
```

#### Example 4: Major 워크플로우와 연계

```bash
# 1. Major 워크플로우로 기능 개발
/major user-dashboard

# 2. 개발 완료 후 커밋
/commit

# 3. PR 생성 (spec.md, plan.md, tasks.md 자동 연동)
/pr

# 자동으로 생성되는 PR body:
# - spec.md의 Overview가 작업 내용에 포함
# - tasks.md의 체크리스트가 테스트 섹션에 포함
# - 관련 이슈 번호 자동 추출
```

### PR Review

#### Example: Reviewing a Feature PR

```bash
/pr-review 456

# Or current branch
/pr-review current
```

#### Output
```markdown
📋 PR #456: Add Shopping Cart Feature
=====================================

📊 Change Statistics:
• Files: 15 changed (+892 / -45)
• Commits: 8
• Author: @developer

🎯 Review Summary:
┌──────────────┬────────┬─────────────────────┐
│ Category     │ Grade  │ Findings            │
├──────────────┼────────┼─────────────────────┤
│ 🔒 Security  │ ✅ Pass │ No issues           │
│ ⚡ Performance│ ⚠️ Warn │ 2 optimizations    │
│ 🏗️ Architecture│ ✅ Pass │ FSD compliant      │
│ 🎯 Types     │ ✅ Pass │ Fully typed        │
│ 🧪 Tests     │ ⚠️ Warn │ Coverage 72%       │
└──────────────┴────────┴─────────────────────┘

⚠️ Performance Issues:

1. CartList.tsx:45
   Missing useMemo for expensive calculation

2. useCart.ts:78
   Unnecessary re-renders on cart update

Recommended Actions:
- Add useMemo for cart total calculation
- Optimize cart state updates
```

## 🏢 Enterprise Patterns

### Example: Microservice Integration

```bash
/triage "Integrate with payment microservice using gRPC"

# Major workflow for complex integration
/major payment-service-integration
```

#### Generated Assets
1. Proto file definitions
2. Generated TypeScript clients
3. Service abstraction layer
4. Comprehensive error handling
5. Circuit breaker implementation
6. Integration tests with mock server

### Example: Database Migration

```bash
/triage "Add multi-tenancy support to existing database"

# Major workflow with careful planning
/major multi-tenancy-migration
```

#### Safety Measures
- Backup strategy documented
- Rollback plan included
- Migration scripts with validation
- Zero-downtime deployment approach

## 🔧 DevOps & CI/CD

### Example: GitHub Actions Workflow

```bash
/triage "Setup CI/CD pipeline with testing and deployment"

# Creates comprehensive pipeline
/major cicd-pipeline
```

#### Generated Workflows
```yaml
# .github/workflows/ci.yml
- Type checking
- Linting
- Unit tests
- E2E tests
- Build verification
- Coverage reporting

# .github/workflows/cd.yml
- Staging deployment
- Production deployment
- Rollback mechanism
- Health checks
```

## 📊 Performance Optimization

### Example: React Performance Audit

```bash
/triage "App is slow, optimize React performance"

# Minor workflow with performance focus
/minor react-performance-optimization
```

#### Optimizations Applied
1. **Component Level**:
   - Added React.memo to pure components
   - Implemented useMemo/useCallback
   - Lazy loading with Suspense

2. **State Management**:
   - Normalized state structure
   - Implemented selectors
   - Reduced unnecessary subscriptions

3. **Bundle Size**:
   - Code splitting by route
   - Dynamic imports
   - Tree shaking optimization

## 🎯 Common Patterns

### Form Handling

```bash
/triage "Create user registration form with validation"

# Activates form-validation skill automatically
/minor registration-form
```

#### Generated Code
```typescript
// Zod schema
const registrationSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  confirmPassword: z.string()
}).refine(/* password match validation */);

// React Hook Form integration
const { register, handleSubmit, formState } = useForm({
  resolver: zodResolver(registrationSchema)
});

// Full component with error handling
```

### API Integration

```bash
/triage "Integrate weather API with caching"

# Activates api-integration skill
/minor weather-api-integration
```

#### Generated Structure
```typescript
// API client
class WeatherAPI extends BaseAPIClient {
  async getCurrentWeather(city: string) {
    return this.get(`/weather/${city}`, {
      cache: { ttl: 300 } // 5 min cache
    });
  }
}

// React Query hook
export function useWeather(city: string) {
  return useQuery({
    queryKey: ['weather', city],
    queryFn: () => weatherAPI.getCurrentWeather(city),
    staleTime: 5 * 60 * 1000
  });
}
```

## 🚀 Workflow Combinations

### Full Feature Development

```bash
# Day 1: Specification
/triage "Build user dashboard with analytics"
→ Major workflow

# Day 2: Development
/major user-dashboard
→ Spec created
→ Components built
→ Tests written

# Day 3: Bug fixes
/minor fix-dashboard-layout
/minor add-missing-metrics

# Day 4: Polish
/micro update-chart-colors
/micro fix-typos

# Ready for review
/commit
/pr              # PR 생성
/pr-review current  # PR 리뷰
```

### Rapid Prototyping

```bash
# Quick iteration mode
/micro scaffold-components
/minor add-basic-logic
/micro style-updates
/commit --no-verify  # Skip checks for prototype
```

## 📈 Metrics & Results

### Real Project Results

| Project Type | Workflow Used | Time Saved | Token Reduction |
|-------------|---------------|------------|-----------------|
| E-commerce Feature | Major | 6 hours | 62% |
| Bug Fix Sprint | Minor (×12) | 4 hours | 78% |
| UI Updates | Micro (×20) | 2 hours | 86% |
| API Integration | Major + Minor | 5 hours | 71% |
| Performance Opt | Minor | 3 hours | 74% |

### Before/After Comparison

#### Before Claude Workflows
- Manual specification writing: 2 hours
- Component scaffolding: 1 hour
- Test writing: 2 hours
- Documentation: 1 hour
- **Total: 6 hours**

#### With Claude Workflows
- `/major feature-name`: 10 minutes
- Automated implementation: 30 minutes
- Review and adjustments: 20 minutes
- **Total: 1 hour**

## 🎓 Learning Path

### Beginner
1. Start with `/triage` for everything
2. Learn the difference between workflows
3. Use `/commit` for better commit messages

### Intermediate
1. Use specific workflows directly
2. Combine workflows for complex tasks
3. Leverage sub-agents explicitly

### Advanced
1. Create custom workflows
2. Extend existing skills
3. Contribute new patterns

## 💡 Pro Tips

### Token Optimization
```bash
# Instead of multiple Major workflows
/major feature1
/major feature2  # Wasteful

# Better: Combine related features
/major user-management  # Includes profile, settings, preferences
```

### Parallel Execution
```bash
# Run independent tasks simultaneously
/minor fix-header & /minor fix-footer &

# Wait for all to complete
wait
```

### Caching Strategy
```bash
# Reuse analysis from previous runs
/triage --cache "same task as yesterday"
```

---

For more examples and patterns, check our [GitHub Discussions](https://github.com/Liamns/claude-workflows/discussions)!