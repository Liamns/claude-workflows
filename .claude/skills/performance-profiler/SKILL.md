---
name: performance-profiler
description: 애플리케이션 성능 프로파일링과 병목 지점 분석을 제공합니다. 번들 크기 분석, 로딩 성능, 런타임 성능 최적화를 안내합니다. reviewer-unified에서 활용됩니다.
allowed-tools: Read, Grep, Glob, Bash(npm run build:*), Bash(yarn build:*)
---

# Performance Profiler Skill

애플리케이션의 성능을 분석하고 병목 지점을 식별하여 최적화 방안을 제시합니다.

## 사용 시점

다음과 같은 상황에서 활성화됩니다:

- 번들 크기 분석 및 최적화
- 로딩 성능 개선
- 런타임 성능 프로파일링
- 메모리 누수 탐지
- PR 성능 영향도 분석

## 핵심 분석 영역

### 1. 번들 크기 분석

**Webpack Bundle Analyzer:**
```bash
# 분석 실행
npm run build -- --analyze
# 또는
ANALYZE=true npm run build
```

**번들 크기 체크포인트:**
```markdown
## 번들 크기 기준

### Critical (즉시 수정)
- 메인 번들 > 500KB (gzipped)
- 단일 청크 > 300KB (gzipped)
- node_modules 비율 > 70%

### Warning (개선 권장)
- 메인 번들 > 300KB (gzipped)
- 중복 의존성 존재
- Tree-shaking 미적용 라이브러리

### 최적화 방법
1. 코드 스플리팅 적용
2. 동적 import 활용
3. 라이브러리 대체 (moment → dayjs, lodash → lodash-es)
4. Tree-shaking 확인
```

**코드 스플리팅 패턴:**
```typescript
// ❌ 정적 import
import { HeavyComponent } from './HeavyComponent';

// ✅ 동적 import (라우트 레벨)
const HeavyComponent = lazy(() => import('./HeavyComponent'));

// ✅ 조건부 로딩
const loadAnalytics = () => import('./analytics');

if (shouldTrack) {
  loadAnalytics().then(module => module.init());
}
```

### 2. 로딩 성능 분석

**Core Web Vitals 기준:**
```markdown
## Core Web Vitals 목표

### LCP (Largest Contentful Paint)
- Good: < 2.5s
- Needs Improvement: 2.5s - 4.0s
- Poor: > 4.0s

### FID (First Input Delay)
- Good: < 100ms
- Needs Improvement: 100ms - 300ms
- Poor: > 300ms

### CLS (Cumulative Layout Shift)
- Good: < 0.1
- Needs Improvement: 0.1 - 0.25
- Poor: > 0.25
```

**검사 패턴:**
```bash
# 이미지 최적화 확인
grep -rE "<img.*src=" src/ | grep -v "loading=|srcSet="

# 폰트 로딩 확인
grep -rE "@font-face|font-display" src/

# Preload/Prefetch 확인
grep -rE "rel=\"preload\"|rel=\"prefetch\"" public/
```

**최적화 체크리스트:**
```typescript
// ✅ 이미지 최적화
<Image
  src="/hero.jpg"
  alt="Hero"
  width={800}
  height={600}
  priority // LCP 이미지
  placeholder="blur"
/>

// ✅ 폰트 최적화
@font-face {
  font-family: 'CustomFont';
  font-display: swap; // FOUT 허용
  src: url('/fonts/custom.woff2') format('woff2');
}

// ✅ Critical CSS 인라인
<style dangerouslySetInnerHTML={{ __html: criticalCSS }} />
```

### 3. 런타임 성능 분석

**React 렌더링 성능:**
```typescript
// 프로파일러 활용
import { Profiler } from 'react';

function onRenderCallback(
  id: string,
  phase: 'mount' | 'update',
  actualDuration: number,
  baseDuration: number,
  startTime: number,
  commitTime: number,
) {
  if (actualDuration > 16) { // 60fps 기준
    console.warn(`Slow render: ${id} took ${actualDuration}ms`);
  }
}

<Profiler id="MainContent" onRender={onRenderCallback}>
  <MainContent />
</Profiler>
```

**성능 측정 유틸리티:**
```typescript
// 성능 측정 래퍼
function measurePerformance<T>(
  name: string,
  fn: () => T,
): T {
  const start = performance.now();
  const result = fn();
  const end = performance.now();

  console.log(`${name}: ${(end - start).toFixed(2)}ms`);

  return result;
}

// 비동기 버전
async function measureAsync<T>(
  name: string,
  fn: () => Promise<T>,
): Promise<T> {
  const start = performance.now();
  const result = await fn();
  const end = performance.now();

  console.log(`${name}: ${(end - start).toFixed(2)}ms`);

  return result;
}
```

### 4. 메모리 분석

**메모리 누수 패턴 검사:**
```bash
# 이벤트 리스너 정리 확인
grep -rE "addEventListener" src/ | grep -v "removeEventListener"

# setInterval/setTimeout 정리 확인
grep -rE "setInterval|setTimeout" src/ | grep -v "clearInterval|clearTimeout"

# AbortController 사용 확인
grep -rE "fetch\(" src/ | grep -v "AbortController|signal"
```

**메모리 누수 방지 패턴:**
```typescript
// ❌ 메모리 누수 위험
useEffect(() => {
  window.addEventListener('resize', handleResize);
  // cleanup 없음!
}, []);

// ✅ 올바른 cleanup
useEffect(() => {
  window.addEventListener('resize', handleResize);
  return () => {
    window.removeEventListener('resize', handleResize);
  };
}, []);

// ✅ AbortController 활용
useEffect(() => {
  const controller = new AbortController();

  fetch('/api/data', { signal: controller.signal })
    .then(res => res.json())
    .then(setData)
    .catch(err => {
      if (err.name !== 'AbortError') throw err;
    });

  return () => controller.abort();
}, []);
```

### 5. API 성능 분석

**API 응답 시간 기준:**
```markdown
## API 성능 기준

### Response Time
- Excellent: < 100ms
- Good: 100ms - 500ms
- Acceptable: 500ms - 1000ms
- Poor: > 1000ms

### 검사 항목
1. N+1 쿼리 문제
2. 불필요한 데이터 fetch
3. 캐싱 미적용
4. 병렬 요청 미활용
```

**최적화 패턴:**
```typescript
// ❌ 순차적 요청
const user = await fetchUser(id);
const posts = await fetchPosts(id);
const comments = await fetchComments(id);

// ✅ 병렬 요청
const [user, posts, comments] = await Promise.all([
  fetchUser(id),
  fetchPosts(id),
  fetchComments(id),
]);

// ✅ React Query 캐싱
const { data } = useQuery({
  queryKey: ['user', id],
  queryFn: () => fetchUser(id),
  staleTime: 5 * 60 * 1000, // 5분
  gcTime: 30 * 60 * 1000, // 30분
});
```

### 6. 데이터베이스 성능

**쿼리 성능 검사:**
```bash
# 인덱스 없는 쿼리 검색
grep -rE "findMany|findAll" src/ | grep -v "where.*indexed"

# N+1 패턴 검색
grep -rE "for.*await.*find" src/
```

**Prisma 최적화:**
```typescript
// ❌ N+1 문제
const users = await prisma.user.findMany();
for (const user of users) {
  const posts = await prisma.post.findMany({
    where: { authorId: user.id }
  });
}

// ✅ Include로 해결
const users = await prisma.user.findMany({
  include: {
    posts: true,
  },
});

// ✅ 필요한 필드만 선택
const users = await prisma.user.findMany({
  select: {
    id: true,
    name: true,
    email: true,
  },
});
```

## 성능 보고서 형식

```markdown
## 📊 성능 분석 보고서

### 분석 대상
- 애플리케이션: [앱 이름]
- 분석 일시: YYYY-MM-DD
- 분석 범위: 번들/로딩/런타임/API

### 요약

| 영역 | 현재 상태 | 목표 | 상태 |
|------|-----------|------|------|
| 번들 크기 | 450KB | <300KB | 🟡 |
| LCP | 2.1s | <2.5s | 🟢 |
| FID | 85ms | <100ms | 🟢 |
| CLS | 0.15 | <0.1 | 🟡 |

### 발견된 문제

#### 🔴 Critical
1. **moment.js 전체 번들 포함**
   - 영향: +250KB
   - 해결: dayjs로 대체

#### 🟡 Warning
1. **이미지 lazy loading 미적용**
   - 영향: LCP 지연
   - 해결: loading="lazy" 추가

#### 🟢 Good
- Tree-shaking 정상 작동
- 코드 스플리팅 적용됨

### 권장 조치
1. moment → dayjs 마이그레이션 (예상 -230KB)
2. 이미지 최적화 적용 (예상 LCP -0.5s)
3. 폰트 preload 추가 (예상 FCP -0.2s)

### 예상 개선 효과
- 번들 크기: 450KB → 220KB (-51%)
- LCP: 2.1s → 1.4s (-33%)
```

## 검토 체크리스트

### 번들 분석
- [ ] 메인 번들 크기 확인
- [ ] 중복 의존성 검사
- [ ] Tree-shaking 확인
- [ ] 코드 스플리팅 적용

### 로딩 성능
- [ ] Core Web Vitals 측정
- [ ] 이미지 최적화 확인
- [ ] 폰트 로딩 최적화
- [ ] Critical CSS 확인

### 런타임 성능
- [ ] 렌더링 병목 확인
- [ ] 메모리 누수 검사
- [ ] 이벤트 핸들러 최적화

### API/데이터
- [ ] API 응답 시간 확인
- [ ] N+1 쿼리 검사
- [ ] 캐싱 전략 확인

## 연동 Agent/Skill

- **reviewer-unified**: PR 성능 영향도 분석
- **react-optimization**: React 특화 최적화
- **implementer-unified**: 성능 개선 구현

## 사용 예시

```
사용자: "앱이 느린 것 같아요. 성능 분석해줘"

1. 번들 크기 분석
2. Core Web Vitals 확인
3. 코드 패턴 검사
4. performance-profiler 기준 적용
5. 최적화 권장사항 제시
6. 보고서 생성
```
