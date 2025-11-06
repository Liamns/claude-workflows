# Changelog 포맷 템플릿

## 기본 구조

```markdown
## 📅 {{date}} ({{day_of_week}})

### 👥 Contributors
{{#each contributors}}
- {{name}} ({{commit_count}} commits)
{{/each}}

### ✨ Features ({{feature_count}})
{{#each features}}
- {{message}} ([{{hash}}]({{commit_url}}))
{{#if files_changed > 2}}
  - 변경 파일: {{files_changed}}개 ({{lines_added}}/{{lines_deleted}})
{{/if}}
{{/each}}

### 🐛 Bug Fixes ({{bugfix_count}})
{{#each bugfixes}}
- {{message}} ([{{hash}}]({{commit_url}}))
{{/each}}

### ♻️ Refactoring ({{refactor_count}})
{{#each refactorings}}
- {{message}} ([{{hash}}]({{commit_url}}))
{{/each}}

### 📊 Statistics
- Total Commits: {{total_commits}}
- Files Changed: {{total_files}}
- Lines: +{{lines_added}} / -{{lines_deleted}}
```

## 변수 설명

- `{{date}}`: YYYY-MM-DD 형식
- `{{day_of_week}}`: 요일 (월/화/수/목/금/토/일)
- `{{commit_url}}`: GitHub 커밋 URL
- `{{lines_added}}`: 추가된 라인 수
- `{{lines_deleted}}`: 삭제된 라인 수
