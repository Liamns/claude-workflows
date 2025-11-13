import { z } from 'zod';

/**
 * 문서 검증 상태
 */
export type ValidationStatus = 'pass' | 'warning' | 'error';

/**
 * 문서 타입
 */
export type DocumentType = 'spec' | 'research' | 'data-model' | 'plan' | 'tasks' | 'quickstart';

/**
 * 문서 검증 결과
 */
export interface DocumentValidationResult {
  /** 문서 파일 경로 */
  documentPath: string;
  /** 한글 비율 (0-100) */
  koreanRatio: number;
  /** 검증 상태 */
  status: ValidationStatus;
  /** 전체 문자 수 (코드 블록 제외) */
  totalChars: number;
  /** 한글 문자 수 */
  koreanChars: number;
  /** 사용자에게 표시할 메시지 */
  message: string;
}

/**
 * 문서 생성 및 검증 설정
 */
export interface DocumentGenerationConfig {
  /** 한글 강제 여부 */
  enforceKorean: boolean;
  /** 최소 한글 비율 (default: 70) */
  minKoreanRatio: number;
  /** 경고 임계값 (default: 50) */
  warningThreshold: number;
  /** 최대 재시도 횟수 (default: 3) */
  maxRetries: number;
  /** 생성 시 자동 검증 (default: true) */
  validateOnGeneration: boolean;
}

/**
 * 재생성 요청 정보
 */
export interface RegenerationRequest {
  /** 문서 경로 */
  documentPath: string;
  /** 재생성 이유 */
  reason: string;
  /** 재시도 횟수 */
  retryCount: number;
  /** 이전 한글 비율 */
  previousKoreanRatio: number;
}

/**
 * 기본 설정값
 */
export const DEFAULT_CONFIG: DocumentGenerationConfig = {
  enforceKorean: true,
  minKoreanRatio: 60,
  warningThreshold: 45,
  maxRetries: 3,
  validateOnGeneration: true,
};

/**
 * Zod 스키마: DocumentValidationResult
 */
export const DocumentValidationResultSchema = z.object({
  documentPath: z.string().min(1, '문서 경로는 필수입니다'),
  koreanRatio: z.number().min(0).max(100, '한글 비율은 0-100 사이 값이어야 합니다'),
  status: z.enum(['pass', 'warning', 'error']),
  totalChars: z.number().min(0, '전체 문자 수는 0 이상이어야 합니다'),
  koreanChars: z.number().min(0, '한글 문자 수는 0 이상이어야 합니다'),
  message: z.string().min(1, '메시지는 필수입니다'),
});

/**
 * Zod 스키마: DocumentGenerationConfig
 */
export const DocumentGenerationConfigSchema = z.object({
  enforceKorean: z.boolean().default(true),
  minKoreanRatio: z.number().min(0).max(100).default(60),
  warningThreshold: z.number().min(0).max(100).default(45),
  maxRetries: z.number().min(1).max(5).default(3),
  validateOnGeneration: z.boolean().default(true),
}).refine(
  (config) => config.minKoreanRatio > config.warningThreshold,
  {
    message: 'minKoreanRatio는 warningThreshold보다 커야 합니다',
    path: ['minKoreanRatio'],
  }
);
