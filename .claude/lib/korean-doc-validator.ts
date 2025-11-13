/**
 * 한글 문서화 강제 - 핵심 검증 로직
 */

import * as fs from 'fs';
import {
  DocumentValidationResult,
  DocumentGenerationConfig,
  ValidationStatus,
  DEFAULT_CONFIG,
} from './types/korean-doc-types';

/**
 * 코드 블록 및 기술적 내용 제거
 * @param text 원본 텍스트
 * @returns 정제된 텍스트
 */
export function removeCodeBlocksAndTechContent(text: string): string {
  let cleaned = text;

  // 1. Markdown 코드 블록 제거 (```...```)
  cleaned = cleaned.replace(/```[\s\S]*?```/g, '');

  // 2. 인라인 코드 제거 (`...`)
  cleaned = cleaned.replace(/`[^`]+`/g, '');

  // 3. 파일 경로 제거 (/path/to/file, ./path)
  cleaned = cleaned.replace(/\/[a-zA-Z0-9_\-\/\.]+/g, '');
  cleaned = cleaned.replace(/\.\\/[a-zA-Z0-9_\-\/\.]+/g, '');

  // 4. URL 제거 (http://, https://)
  cleaned = cleaned.replace(/https?:\/\/[^\s]+/g, '');

  // 5. CamelCase/PascalCase 제거 (DocumentValidationResult, validateDocument)
  cleaned = cleaned.replace(/\b[A-Z][a-z]+(?:[A-Z][a-z]+)+\b/g, '');
  cleaned = cleaned.replace(/\b[a-z]+(?:[A-Z][a-z]+)+\b/g, '');

  // 6. kebab-case 제거 (korean-documentation, epic-workflow)
  cleaned = cleaned.replace(/\b[a-z]+(?:-[a-z]+)+\b/g, '');

  // 7. 대문자+숫자 패턴 제거 (FR-001, US1, T001, P1)
  cleaned = cleaned.replace(/\b[A-Z]+\d+\b/g, '');
  cleaned = cleaned.replace(/\b[A-Z]+-\d+\b/g, '');

  // 8. 영어 단어와 숫자 혼합 제거 (Step 13.5, Phase 2)
  cleaned = cleaned.replace(/\b[A-Z][a-z]+\s+\d+(?:\.\d+)?\b/g, '');

  // 9. 모든 영어 단어 제거 (3글자 이상, 기술 용어 포함)
  // React, Query, TypeScript, Zod, Vitest 등
  cleaned = cleaned.replace(/\b[A-Za-z]{3,}\b/g, '');

  // 10. 남은 단일/이중 영어 문자 제거 (a, to, is, it 등)
  cleaned = cleaned.replace(/\b[A-Za-z]{1,2}\b/g, '');

  // 11. 특수문자 제거 (점, 콤마, 대시 등은 유지하지만 연속된 것 제거)
  cleaned = cleaned.replace(/[_]+/g, ' ');

  return cleaned;
}

/**
 * 한글 비율 계산
 * @param text 원본 텍스트
 * @returns 한글 비율 (0-100)
 */
export function calculateKoreanRatio(text: string): number {
  // 1. 코드 블록, 인라인 코드, 파일 경로, URL, 영어 단어 제거
  const cleanedText = removeCodeBlocksAndTechContent(text);

  // 2. 공백 제외한 의미있는 문자 수 계산
  const textWithoutSpaces = cleanedText.replace(/\s/g, '');
  const totalChars = textWithoutSpaces.length;

  // 3. 한글 문자 수 계산
  const koreanChars = (textWithoutSpaces.match(/[가-힣]/g) || []).length;

  // 4. 비율 계산 (0-100)
  return totalChars > 0 ? (koreanChars / totalChars) * 100 : 0;
}

/**
 * 단일 문서 검증
 * @param documentPath 문서 파일 경로
 * @param config 검증 설정
 * @returns 검증 결과
 */
export function validateDocument(
  documentPath: string,
  config: DocumentGenerationConfig
): DocumentValidationResult {
  try {
    // 1. 파일 읽기
    const content = fs.readFileSync(documentPath, 'utf-8');

    // 2. 한글 비율 계산
    const cleanedContent = removeCodeBlocksAndTechContent(content);
    const totalChars = cleanedContent.length;
    const koreanChars = (cleanedContent.match(/[가-힣]/g) || []).length;
    const koreanRatio = totalChars > 0 ? (koreanChars / totalChars) * 100 : 0;

    // 3. 상태 결정
    let status: ValidationStatus;
    if (koreanRatio >= config.minKoreanRatio) {
      status = 'pass';
    } else if (koreanRatio >= config.warningThreshold) {
      status = 'warning';
    } else {
      status = 'error';
    }

    // 4. 메시지 생성
    let message: string;
    if (status === 'pass') {
      message = `✅ ${documentPath} - 한글 비율: ${koreanRatio.toFixed(1)}% (양호)`;
    } else if (status === 'warning') {
      message = `⚠️ ${documentPath} - 한글 비율: ${koreanRatio.toFixed(1)}% (낮음, 수정 권장)`;
    } else {
      message = `❌ ${documentPath} - 한글 비율: ${koreanRatio.toFixed(1)}% (불충분, 재생성 필요)`;
    }

    return {
      documentPath,
      koreanRatio,
      status,
      totalChars,
      koreanChars,
      message,
    };
  } catch (error) {
    return {
      documentPath,
      koreanRatio: 0,
      status: 'error',
      totalChars: 0,
      koreanChars: 0,
      message: `❌ ${documentPath} - 파일을 읽을 수 없습니다: ${(error as Error).message}`,
    };
  }
}

/**
 * 여러 문서 검증
 * @param documentPaths 문서 파일 경로 배열
 * @param config 검증 설정
 * @returns 검증 결과 배열
 */
export function validateDocuments(
  documentPaths: string[],
  config: DocumentGenerationConfig
): DocumentValidationResult[] {
  return documentPaths
    .filter(path => fs.existsSync(path))
    .map(path => validateDocument(path, config));
}

/**
 * 비동기 문서 검증
 * @param documentPaths 문서 파일 경로 배열
 * @param config 검증 설정
 * @returns 검증 결과 배열 (Promise)
 */
export async function validateDocumentsAsync(
  documentPaths: string[],
  config: DocumentGenerationConfig
): Promise<DocumentValidationResult[]> {
  const results = await Promise.all(
    documentPaths
      .filter(path => fs.existsSync(path))
      .map(path => Promise.resolve(validateDocument(path, config)))
  );
  return results;
}
