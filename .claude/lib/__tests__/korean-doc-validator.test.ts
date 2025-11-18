/**
 * 한글 문서화 강제 - 단위 테스트
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';
import {
  removeCodeBlocksAndTechContent,
  calculateKoreanRatio,
  validateDocument,
  validateDocuments,
  validateDocumentsAsync,
} from '../korean-doc-validator';
import { DEFAULT_CONFIG } from '../types/korean-doc-types';

describe('removeCodeBlocksAndTechContent', () => {
  // T004: Markdown 코드 블록 제거
  it('should remove Markdown code blocks', () => {
    const text = `
이것은 한글 텍스트입니다.

\`\`\`typescript
const foo = 'bar';
console.log(foo);
\`\`\`

다시 한글 텍스트입니다.
`;
    const result = removeCodeBlocksAndTechContent(text);
    expect(result).not.toContain('const foo');
    expect(result).not.toContain('console.log');
    expect(result).toContain('이것은 한글 텍스트입니다');
    expect(result).toContain('다시 한글 텍스트입니다');
  });

  // T005: 인라인 코드 제거
  it('should remove inline code', () => {
    const text = '이것은 `inline code` 테스트입니다. `another` 코드도 있습니다.';
    const result = removeCodeBlocksAndTechContent(text);
    expect(result).not.toContain('`inline code`');
    expect(result).not.toContain('`another`');
    expect(result).toContain('이것은');
    expect(result).toContain('테스트입니다');
  });

  // T006: 파일 경로 제거
  it('should remove file paths', () => {
    const text = '파일은 /usr/local/bin/file.ts 또는 ./relative/path.md에 있습니다.';
    const result = removeCodeBlocksAndTechContent(text);
    expect(result).not.toContain('/usr/local/bin/file.ts');
    expect(result).not.toContain('./relative/path.md');
    expect(result).toContain('파일은');
    expect(result).toContain('에 있습니다');
  });

  // T007: URL 제거
  it('should remove URLs', () => {
    const text = '문서는 https://example.com 또는 http://test.org에서 확인하세요.';
    const result = removeCodeBlocksAndTechContent(text);
    expect(result).not.toContain('https://example.com');
    expect(result).not.toContain('http://test.org');
    expect(result).toContain('문서는');
    expect(result).toContain('에서 확인하세요');
  });

  // T008: 복합 테스트
  it('should handle mixed content correctly', () => {
    const text = `
# 제목

이것은 한글 설명입니다. \`code\`도 있고 /path/to/file도 있습니다.

\`\`\`bash
echo "hello"
\`\`\`

자세한 내용은 https://docs.example.com을 참조하세요.
`;
    const result = removeCodeBlocksAndTechContent(text);
    expect(result).toContain('제목');
    expect(result).toContain('이것은 한글 설명입니다');
    expect(result).not.toContain('`code`');
    expect(result).not.toContain('/path/to/file');
    expect(result).not.toContain('echo "hello"');
    expect(result).not.toContain('https://docs.example.com');
  });
});

describe('calculateKoreanRatio', () => {
  // T009: 100% 한글
  it('should return 100 for pure Korean text', () => {
    const text = '이것은 완전히 한글로만 작성된 문서입니다';
    const ratio = calculateKoreanRatio(text);
    expect(ratio).toBeGreaterThan(95);
  });

  // T010: 0% 한글
  it('should return 0 for text without Korean', () => {
    const text = 'This is English only text without any Korean';
    const ratio = calculateKoreanRatio(text);
    expect(ratio).toBe(0);
  });

  // T011: 혼합 텍스트
  it('should calculate correct ratio for mixed text', () => {
    const text = '한글 Korean 한글 Korean 한글';
    const ratio = calculateKoreanRatio(text);
    expect(ratio).toBeGreaterThan(40);
    expect(ratio).toBeLessThan(80);
  });

  // T012: 코드 블록 제외 후 계산
  it('should exclude code blocks when calculating ratio', () => {
    const text = `
한글 텍스트입니다.

\`\`\`typescript
const englishCode = 'this should be excluded';
\`\`\`

다시 한글입니다.
`;
    const ratio = calculateKoreanRatio(text);
    expect(ratio).toBeGreaterThan(70);
  });
});

describe('validateDocument', () => {
  const testDir = path.join(__dirname, 'test-documents');

  beforeEach(() => {
    if (!fs.existsSync(testDir)) {
      fs.mkdirSync(testDir, { recursive: true });
    }
  });

  afterEach(() => {
    if (fs.existsSync(testDir)) {
      fs.rmSync(testDir, { recursive: true, force: true });
    }
  });

  // T013: 높은 한글 비율 (pass)
  it('should return pass status for high Korean ratio', () => {
    const testFile = path.join(testDir, 'high-korean.md');
    const content = '이 문서는 거의 대부분 한글로 작성되었습니다. 한글 비율이 매우 높습니다.';
    fs.writeFileSync(testFile, content, 'utf-8');

    const result = validateDocument(testFile, DEFAULT_CONFIG);
    expect(result.status).toBe('pass');
    expect(result.koreanRatio).toBeGreaterThanOrEqual(70);
    expect(result.message).toContain('✅');
  });

  // T014: 중간 한글 비율 (warning)
  it('should return warning status for medium Korean ratio', () => {
    const testFile = path.join(testDir, 'medium-korean.md');
    const content = '한글 Korean text 한글 English text 한글 More English';
    fs.writeFileSync(testFile, content, 'utf-8');

    const result = validateDocument(testFile, DEFAULT_CONFIG);
    expect(result.status).toBe('warning');
    expect(result.koreanRatio).toBeGreaterThanOrEqual(50);
    expect(result.koreanRatio).toBeLessThan(70);
    expect(result.message).toContain('⚠️');
  });

  // T015: 낮은 한글 비율 (error)
  it('should return error status for low Korean ratio', () => {
    const testFile = path.join(testDir, 'low-korean.md');
    const content = 'This is mostly English text with very little 한글 content here.';
    fs.writeFileSync(testFile, content, 'utf-8');

    const result = validateDocument(testFile, DEFAULT_CONFIG);
    expect(result.status).toBe('error');
    expect(result.koreanRatio).toBeLessThan(50);
    expect(result.message).toContain('❌');
  });

  // T016: 파일 없음 (error)
  it('should return error for non-existent file', () => {
    const testFile = path.join(testDir, 'non-existent.md');
    const result = validateDocument(testFile, DEFAULT_CONFIG);
    expect(result.status).toBe('error');
    expect(result.koreanRatio).toBe(0);
    expect(result.message).toContain('파일을 읽을 수 없습니다');
  });
});

describe('validateDocuments', () => {
  const testDir = path.join(__dirname, 'test-documents-multi');

  beforeEach(() => {
    if (!fs.existsSync(testDir)) {
      fs.mkdirSync(testDir, { recursive: true });
    }
  });

  afterEach(() => {
    if (fs.existsSync(testDir)) {
      fs.rmSync(testDir, { recursive: true, force: true });
    }
  });

  it('should validate multiple documents', () => {
    const file1 = path.join(testDir, 'doc1.md');
    const file2 = path.join(testDir, 'doc2.md');

    fs.writeFileSync(file1, '이것은 한글 문서입니다.', 'utf-8');
    fs.writeFileSync(file2, 'This is English document.', 'utf-8');

    const results = validateDocuments([file1, file2], DEFAULT_CONFIG);
    expect(results).toHaveLength(2);
    expect(results[0].status).toBe('pass');
    expect(results[1].status).toBe('error');
  });

  it('should filter out non-existent files', () => {
    const file1 = path.join(testDir, 'exists.md');
    const file2 = path.join(testDir, 'not-exists.md');

    fs.writeFileSync(file1, '한글 문서', 'utf-8');

    const results = validateDocuments([file1, file2], DEFAULT_CONFIG);
    expect(results).toHaveLength(1);
    expect(results[0].documentPath).toBe(file1);
  });
});

describe('validateDocumentsAsync', () => {
  const testDir = path.join(__dirname, 'test-documents-async');

  beforeEach(() => {
    if (!fs.existsSync(testDir)) {
      fs.mkdirSync(testDir, { recursive: true });
    }
  });

  afterEach(() => {
    if (fs.existsSync(testDir)) {
      fs.rmSync(testDir, { recursive: true, force: true });
    }
  });

  it('should validate documents asynchronously', async () => {
    const file1 = path.join(testDir, 'async1.md');
    const file2 = path.join(testDir, 'async2.md');

    fs.writeFileSync(file1, '비동기 한글 문서입니다.', 'utf-8');
    fs.writeFileSync(file2, '또 다른 한글 문서입니다.', 'utf-8');

    const results = await validateDocumentsAsync([file1, file2], DEFAULT_CONFIG);
    expect(results).toHaveLength(2);
    expect(results[0].status).toBe('pass');
    expect(results[1].status).toBe('pass');
  });
});
