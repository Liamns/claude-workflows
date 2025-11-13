# Korean Documentation Validator

한글 문서화 강제를 위한 검증 라이브러리입니다. Major 워크플로우에서 생성된 계획 문서(spec.md, research.md, plan.md, tasks.md 등)의 한글 비율을 자동으로 검증합니다.

## Features

- ✅ **코드 블록 제외**: Markdown 코드 블록, 인라인 코드 자동 제거
- ✅ **기술 용어 제외**: CamelCase, kebab-case, 파일 경로, URL 자동 제거
- ✅ **영어 단어 제외**: 모든 영어 단어를 제거하여 순수 한글 비율 계산
- ✅ **공백 제외**: 공백을 제외한 의미있는 문자 기준으로 비율 계산
- ✅ **병렬 검증**: 여러 문서를 동시에 검증하여 성능 최적화
- ✅ **임계값 설정**: 60% (pass), 45% (warning) 기본값 지원

## Installation

이미 프로젝트에 포함되어 있습니다:

```bash
.claude/lib/
├── korean-doc-validator.ts          # 핵심 검증 로직
├── types/
│   └── korean-doc-types.ts          # TypeScript 타입 정의
└── __tests__/
    └── korean-doc-validator.test.ts # 단위 테스트
```

## Usage

### 기본 사용법

```typescript
import { validateDocuments, DEFAULT_CONFIG } from '.claude/lib/korean-doc-validator';

const documentPaths = [
  '.specify/specs/001-feature/spec.md',
  '.specify/specs/001-feature/plan.md',
  '.specify/specs/001-feature/tasks.md',
];

const results = validateDocuments(documentPaths, DEFAULT_CONFIG);

// 결과 출력
results.forEach(result => {
  console.log(result.message);
});
```

### 비동기 사용법

```typescript
import { validateDocumentsAsync, DEFAULT_CONFIG } from '.claude/lib/korean-doc-validator';

const results = await validateDocumentsAsync(documentPaths, DEFAULT_CONFIG);
```

### 커스텀 설정

```typescript
import { validateDocuments } from '.claude/lib/korean-doc-validator';
import type { DocumentGenerationConfig } from '.claude/lib/types/korean-doc-types';

const customConfig: DocumentGenerationConfig = {
  enforceKorean: true,
  minKoreanRatio: 70,      // 70% 이상만 통과
  warningThreshold: 50,    // 50-69%는 경고
  maxRetries: 5,           // 최대 5회 재시도
  validateOnGeneration: true,
};

const results = validateDocuments(documentPaths, customConfig);
```

## API Reference

### Functions

#### `removeCodeBlocksAndTechContent(text: string): string`

기술적 내용을 제거합니다:
- Markdown 코드 블록 (```...```)
- 인라인 코드 (`...`)
- 파일 경로 (/path, ./path)
- URL (http://, https://)
- CamelCase/PascalCase (DocumentValidationResult)
- kebab-case (korean-documentation)
- 대문자+숫자 (FR-001, US1)
- 모든 영어 단어 (3글자 이상)

#### `calculateKoreanRatio(text: string): number`

한글 비율을 계산합니다 (0-100).

**특징**:
- 공백을 제외한 의미있는 문자 기준
- 기술 용어 자동 제외
- 순수 한글 문자 비율 계산

#### `validateDocument(documentPath: string, config: DocumentGenerationConfig): DocumentValidationResult`

단일 문서를 검증합니다.

**반환값**:
```typescript
{
  documentPath: string;
  koreanRatio: number;    // 한글 비율 (0-100)
  status: 'pass' | 'warning' | 'error';
  totalChars: number;     // 전체 문자 수 (공백 제외)
  koreanChars: number;    // 한글 문자 수
  message: string;        // ✅/⚠️/❌ 포맷 메시지
}
```

#### `validateDocuments(documentPaths: string[], config: DocumentGenerationConfig): DocumentValidationResult[]`

여러 문서를 동시에 검증합니다.

#### `validateDocumentsAsync(documentPaths: string[], config: DocumentGenerationConfig): Promise<DocumentValidationResult[]>`

비동기로 여러 문서를 검증합니다.

### Types

#### `DocumentValidationResult`

```typescript
interface DocumentValidationResult {
  documentPath: string;
  koreanRatio: number;
  status: 'pass' | 'warning' | 'error';
  totalChars: number;
  koreanChars: number;
  message: string;
}
```

#### `DocumentGenerationConfig`

```typescript
interface DocumentGenerationConfig {
  enforceKorean: boolean;           // default: true
  minKoreanRatio: number;           // default: 70
  warningThreshold: number;         // default: 50
  maxRetries: number;               // default: 3
  validateOnGeneration: boolean;    // default: true
}
```

#### `DEFAULT_CONFIG`

기본 설정:

```typescript
const DEFAULT_CONFIG: DocumentGenerationConfig = {
  enforceKorean: true,
  minKoreanRatio: 60,
  warningThreshold: 45,
  maxRetries: 3,
  validateOnGeneration: true,
};
```

## Example Output

```bash
📊 한글 비율 검증 결과:

✅ spec.md - 한글 비율: 72.3% (양호)
⚠️ research.md - 한글 비율: 58.1% (낮음, 수정 권장)
✅ data-model.md - 한글 비율: 65.4% (양호)
❌ tasks.md - 한글 비율: 35.2% (불충분, 재생성 필요)
```

## Status Codes

| Status | 한글 비율 | 아이콘 | 설명 |
|--------|----------|--------|------|
| pass | ≥ 60% | ✅ | 양호 |
| warning | 45-59% | ⚠️ | 낮음, 수정 권장 |
| error | < 45% | ❌ | 불충분, 재생성 필요 |

## Performance

- **단일 문서**: ~1-10ms
- **6개 문서 병렬**: ~10-20ms
- **목표**: < 100ms ✅

## Testing

단위 테스트 파일:

```bash
.claude/lib/__tests__/korean-doc-validator.test.ts
```

테스트 커버리지:
- removeCodeBlocksAndTechContent: 5개 테스트
- calculateKoreanRatio: 4개 테스트
- validateDocument: 4개 테스트
- validateDocuments: 2개 테스트
- validateDocumentsAsync: 1개 테스트

**총 16개 단위 테스트**

## Integration with Major Workflow

major.md의 Step 3, 5, 6에 한글 작성 지시가 추가되어 있습니다:

```markdown
**🔴 매우 중요**: 다음 문서는 **반드시 한글로 작성**하세요.
Overview, User Scenarios, Functional Requirements 등 모든 설명은 한글로 작성하되,
코드 예시, 파일 경로, 기술 용어는 영어를 유지하세요.
```

## Troubleshooting

### 한글 비율이 예상보다 낮게 나옴

**원인**: 공백이 포함되어 계산됨

**해결**: 이미 공백 제외 로직이 구현되어 있습니다 (`textWithoutSpaces = cleanedText.replace(/\s/g, '')`)

### 기술 용어가 제거되지 않음

**원인**: 정규식 패턴이 특정 케이스를 커버하지 못함

**해결**: `removeCodeBlocksAndTechContent()` 함수에 추가 패턴을 추가하세요

### 파일 읽기 실패

**원인**: 파일 경로가 잘못되었거나 권한 문제

**해결**: 절대 경로 사용, 파일 존재 여부 확인

## Version History

- **v1.0.0** (2025-11-13)
  - 초기 릴리즈
  - 한글 비율 계산 알고리즘 구현
  - 공백 제외 로직 추가
  - 모든 영어 단어 제거 기능
  - 병렬 검증 지원

## License

This project is part of Claude Workflow System v3.1.

---

**Feature**: 003-korean-documentation
**Epic**: 001-epic-workflow-system-v31-improvements
**Status**: ✅ Implemented
