---
name: security-owasp-checker
description: OWASP Top 10 취약점을 자동으로 검사합니다. XSS, SQL Injection, 인증 취약점 등을 감지하고 해결책을 제안합니다. reviewer-unified에서 활용됩니다.
allowed-tools: Read, Grep, Glob
---

# Security OWASP Checker Skill

OWASP Top 10 기반 보안 취약점을 검사하고 해결책을 제공합니다.

## 사용 시점

다음과 같은 상황에서 활성화됩니다:

- 코드 리뷰 시 보안 검토
- 새로운 API 엔드포인트 구현
- 사용자 입력 처리 코드 작성
- 인증/인가 로직 구현
- PR 보안 검증

## OWASP Top 10 검사 항목

### 1. A01:2021 - Broken Access Control (접근 제어 취약점)

**검사 패턴:**
```bash
# 권한 검증 누락 검사
grep -r "req\.params\." src/ | grep -v "auth\|guard\|permission"
grep -r "findOne\|findById" src/ | grep -v "where.*userId"
```

**취약점 예시:**
```typescript
// ❌ 취약 - 권한 검증 없음
app.get('/api/users/:id', async (req, res) => {
  const user = await User.findById(req.params.id);
  res.json(user);
});

// ✅ 안전 - 권한 검증
app.get('/api/users/:id', authMiddleware, async (req, res) => {
  const user = await User.findOne({
    where: { id: req.params.id, organizationId: req.user.organizationId }
  });
  if (!user) return res.status(404).json({ error: 'Not found' });
  res.json(user);
});
```

### 2. A02:2021 - Cryptographic Failures (암호화 실패)

**검사 패턴:**
```bash
# 하드코딩된 비밀 검사
grep -rE "(password|secret|api_key|apiKey|token)\s*[:=]\s*['\"][^'\"]+['\"]" src/
grep -rE "MD5|SHA1(?!56)" src/
```

**취약점 예시:**
```typescript
// ❌ 취약 - 하드코딩된 비밀
const API_KEY = 'sk_live_abc123';
const hash = crypto.createHash('MD5').update(password).digest('hex');

// ✅ 안전 - 환경 변수 + 안전한 해시
const API_KEY = process.env.API_KEY;
const hash = await bcrypt.hash(password, 12);
```

### 3. A03:2021 - Injection (인젝션)

**SQL Injection 검사:**
```bash
grep -rE "query\s*\(" src/ | grep -E "\$\{|\+.*req\."
grep -rE "execute\s*\(" src/ | grep -v "prepared"
```

**취약점 예시:**
```typescript
// ❌ 취약 - SQL Injection
const query = `SELECT * FROM users WHERE id = ${userId}`;
await db.query(query);

// ✅ 안전 - Prepared Statement
const query = 'SELECT * FROM users WHERE id = $1';
await db.query(query, [userId]);

// ✅ 안전 - ORM 사용
const user = await User.findOne({ where: { id: userId } });
```

**Command Injection 검사:**
```bash
grep -rE "exec\(|spawn\(|execSync" src/ | grep -E "req\.|params\."
```

### 4. A04:2021 - Insecure Design (불안전한 설계)

**검사 항목:**
- Rate limiting 미적용
- CAPTCHA 없는 중요 기능
- 비즈니스 로직 우회 가능성

```typescript
// ❌ 취약 - Rate limiting 없음
app.post('/api/login', async (req, res) => {
  // 무제한 로그인 시도 가능
});

// ✅ 안전 - Rate limiting 적용
import rateLimit from 'express-rate-limit';

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 5, // 5회 시도
  message: '너무 많은 로그인 시도입니다. 15분 후 다시 시도해주세요.',
});

app.post('/api/login', loginLimiter, async (req, res) => {
  // 로그인 로직
});
```

### 5. A05:2021 - Security Misconfiguration (보안 설정 오류)

**검사 패턴:**
```bash
# 디버그 모드 검사
grep -rE "debug\s*[:=]\s*true" src/
grep -rE "NODE_ENV.*development" src/ | grep -v ".env"

# CORS 설정 검사
grep -rE "cors\(\)" src/ | grep -v "origin:"
```

**취약점 예시:**
```typescript
// ❌ 취약 - 모든 origin 허용
app.use(cors());

// ✅ 안전 - 특정 origin만 허용
app.use(cors({
  origin: ['https://example.com', 'https://app.example.com'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));
```

### 6. A06:2021 - Vulnerable Components (취약한 컴포넌트)

**검사 방법:**
```bash
# npm 취약점 검사
npm audit

# 상세 검사
npm audit --json

# 자동 수정
npm audit fix
```

### 7. A07:2021 - Identification and Authentication Failures (인증 실패)

**검사 패턴:**
```bash
# 약한 비밀번호 정책 검사
grep -rE "password.*minLength.*[0-5]" src/
grep -rE "jwt.*expiresIn.*['\"][0-9]+d['\"]" src/ | grep -v "1d\|2d"
```

**취약점 예시:**
```typescript
// ❌ 취약 - 약한 비밀번호 정책
const passwordSchema = z.string().min(4);

// ✅ 안전 - 강력한 비밀번호 정책
const passwordSchema = z.string()
  .min(8, '최소 8자 이상')
  .regex(/[A-Z]/, '대문자 포함')
  .regex(/[a-z]/, '소문자 포함')
  .regex(/[0-9]/, '숫자 포함')
  .regex(/[^A-Za-z0-9]/, '특수문자 포함');
```

### 8. A08:2021 - Software and Data Integrity Failures (무결성 실패)

**검사 항목:**
- 서명 없는 데이터 신뢰
- CDN 무결성 검증 없음

```html
<!-- ❌ 취약 - 무결성 검증 없음 -->
<script src="https://cdn.example.com/lib.js"></script>

<!-- ✅ 안전 - SRI 적용 -->
<script
  src="https://cdn.example.com/lib.js"
  integrity="sha384-abc123..."
  crossorigin="anonymous"
></script>
```

### 9. A09:2021 - Security Logging and Monitoring Failures (로깅 실패)

**검사 패턴:**
```bash
# 민감 정보 로깅 검사
grep -rE "console\.log.*password\|token\|secret" src/
grep -rE "logger\.(info|debug).*req\.body" src/
```

**취약점 예시:**
```typescript
// ❌ 취약 - 민감 정보 로깅
console.log('Login attempt:', { email, password });

// ✅ 안전 - 민감 정보 제외
console.log('Login attempt:', { email, timestamp: new Date() });
```

### 10. A10:2021 - Server-Side Request Forgery (SSRF)

**검사 패턴:**
```bash
grep -rE "fetch\(.*req\.|axios.*req\." src/
grep -rE "http\.get\(.*params" src/
```

**취약점 예시:**
```typescript
// ❌ 취약 - 사용자 입력 URL 직접 사용
app.get('/proxy', async (req, res) => {
  const response = await fetch(req.query.url);
  res.send(await response.text());
});

// ✅ 안전 - URL 화이트리스트
const ALLOWED_HOSTS = ['api.example.com', 'cdn.example.com'];

app.get('/proxy', async (req, res) => {
  const url = new URL(req.query.url);
  if (!ALLOWED_HOSTS.includes(url.host)) {
    return res.status(403).json({ error: 'Forbidden host' });
  }
  const response = await fetch(url.toString());
  res.send(await response.text());
});
```

## XSS 방지 패턴 (프론트엔드)

```typescript
// ❌ 취약 - 직접 HTML 삽입
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// ✅ 안전 - DOMPurify 사용
import DOMPurify from 'dompurify';

<div dangerouslySetInnerHTML={{
  __html: DOMPurify.sanitize(userContent)
}} />

// ✅ 더 안전 - 텍스트로만 렌더링
<div>{userContent}</div>
```

## 보안 검토 보고서 형식

```markdown
## 🔐 보안 검토 결과

### 검사 대상
- 파일 수: N개
- 검사 항목: OWASP Top 10

### 발견된 취약점

#### 🔴 Critical (즉시 수정 필요)
| 파일 | 라인 | 취약점 | 설명 |
|------|------|--------|------|
| src/api.ts | 45 | SQL Injection | 파라미터 직접 삽입 |

#### 🟡 High (수정 권장)
| 파일 | 라인 | 취약점 | 설명 |
|------|------|--------|------|
| src/auth.ts | 12 | Weak Password | 최소 4자 허용 |

#### 🟢 Medium (개선 제안)
- CORS 설정 강화 권장
- Rate limiting 적용 권장

### 권장 조치
1. SQL Injection: Prepared Statement 사용
2. 비밀번호 정책: 최소 8자 + 복잡성 요구
3. npm audit fix 실행
```

## 검토 체크리스트

- [ ] A01: 접근 제어 검증
- [ ] A02: 암호화 적절성 확인
- [ ] A03: 인젝션 취약점 검사
- [ ] A05: 보안 설정 확인
- [ ] A07: 인증 로직 검토
- [ ] A09: 민감 정보 로깅 확인

## 연동 Agent/Skill

- **reviewer-unified**: 코드 리뷰 시 보안 검토
- **api-designer**: API 설계 시 보안 고려
- **implementer-unified**: 구현 시 보안 패턴 적용

## 사용 예시

```
사용자: "이 코드 보안 검토해줘"

1. 대상 파일 식별
2. OWASP Top 10 기준 검사
3. 취약점 목록 작성
4. 해결책 제안
5. 보고서 생성
```
