# 검증 보고서

**생성 시간**: {{TIMESTAMP}}
**보고서 ID**: {{REPORT_ID}}
**전체 상태**: {{OVERALL_STATUS}}
**일관성 점수**: {{CONSISTENCY_SCORE}}/100

---

## 📊 요약

| 항목 | 결과 |
|------|------|
| 문서 검증 | {{DOC_SUMMARY}} |
| 마이그레이션 검증 | {{MIGRATION_SUMMARY}} |
| 교차 참조 검증 | {{CROSSREF_SUMMARY}} |

---

## 📄 문서 검증 결과

{{DOC_RESULTS}}

### 통과한 문서
{{DOC_PASSED_LIST}}

### 실패한 문서
{{DOC_FAILED_LIST}}

---

## 🔄 마이그레이션 검증 결과

{{MIGRATION_RESULTS}}

### v1.0 → v2.5 시나리오
- 상태: {{V1_STATUS}}
- 종료 코드: {{V1_EXIT_CODE}}
- Deprecated 파일 제거: {{V1_DEPRECATED_COUNT}}개
- Critical 파일 존재: {{V1_CRITICAL_COUNT}}개

### v2.4 → v2.5 시나리오
- 상태: {{V24_STATUS}}
- 종료 코드: {{V24_EXIT_CODE}}
- Deprecated 파일 제거: {{V24_DEPRECATED_COUNT}}개
- Critical 파일 존재: {{V24_CRITICAL_COUNT}}개

---

## 🔗 교차 참조 검증 결과

{{CROSSREF_RESULTS}}

### 통계
- 전체 링크: {{TOTAL_LINKS}}개
- 유효한 링크: {{VALID_LINKS}}개
- 깨진 링크: {{BROKEN_LINKS}}개
- 유효율: {{LINK_VALIDITY}}%

### 깨진 링크 목록
{{BROKEN_LINKS_LIST}}

---

## 📈 상세 메트릭

### 문서별 일치율
{{DOC_CONSISTENCY_TABLE}}

### 파일 통계
- 명령어 파일: {{COMMAND_FILE_COUNT}}개
- 에이전트 파일: {{AGENT_FILE_COUNT}}개
- 스킬 파일: {{SKILL_FILE_COUNT}}개

---

## ⚠️ 경고 및 권장사항

{{WARNINGS_LIST}}

{{RECOMMENDATIONS_LIST}}

---

## 📎 추가 정보

- 실행 시간: {{EXECUTION_TIME}}초
- 검증 모드: {{VALIDATION_MODE}}
- 로그 파일: {{LOG_FILE_PATH}}

---

**보고서 끝**
