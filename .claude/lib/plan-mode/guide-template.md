# Plan Mode Guide Template

## Purpose
This template provides standardized messages to guide users through Plan Mode integration with the Major workflow.

## Guide Message Template

### When to Show
- Display when `/triage` complexity score >= 5 (Major threshold)
- Show before starting Major workflow
- Always provide fallback option

### Message Format

```markdown
📋 복잡한 작업이 감지되었습니다 (복잡도: {{SCORE}}점)

Plan Mode를 사용하여 상세 계획을 수립하시겠습니까?

## Option 1: Plan Mode 사용 (권장) 🎯

Plan Mode에서 체계적인 계획을 수립한 후 구현을 시작할 수 있습니다:

**Step 1.** `Shift+Tab` 누르기
   → Plan Mode 진입 (읽기 전용 모드)

**Step 2.** 다음과 같이 요청하기:
   ```
   "{{FEATURE_NAME}}"의 상세 구현 계획을 작성해주세요.

   다음 항목을 포함해주세요:
   - 주요 목표 및 요구사항
   - 사용자 시나리오
   - 필요한 데이터 모델/엔티티
   - 구현 단계 및 의존성
   - 기술 스택 및 제약사항
   ```

**Step 3.** 계획 검토 및 수정
   → 필요시 추가 질문하여 계획 개선

**Step 4.** 계획 완료 후:
   ```
   이 계획으로 /major 워크플로우를 시작해주세요
   ```
   → 대화 컨텍스트의 계획 내용이 자동으로 참조됩니다

---

## Option 2: 바로 Major 워크플로우 시작 ⚡

Plan Mode를 건너뛰고 질문-응답 방식으로 바로 진행:

```
/major
```

→ Step 2-5에서 필요한 정보를 대화형으로 수집합니다

---

**어떤 방식으로 진행하시겠습니까?**

1️⃣ Plan Mode 사용 (권장)
2️⃣ 바로 Major 시작
```

## Variable Substitution

The template uses the following variables:

- `{{SCORE}}`: Complexity score from /triage (e.g., "12")
- `{{FEATURE_NAME}}`: Feature name from user request (e.g., "사용자 인증 시스템")

## Usage Example

### In /triage command:

```bash
# After complexity calculation
if [ "$COMPLEXITY_SCORE" -ge 5 ]; then
  FEATURE_NAME="$USER_REQUEST"

  # Load template and substitute variables
  GUIDE_MESSAGE=$(cat .claude/lib/plan-mode/guide-template.md | \
    sed "s/{{SCORE}}/$COMPLEXITY_SCORE/g" | \
    sed "s/{{FEATURE_NAME}}/$FEATURE_NAME/g")

  # Display guide message
  echo "$GUIDE_MESSAGE"
fi
```

## Fallback Behavior

**Always ensure fallback option is available:**
- User can choose Option 2 (skip Plan Mode) anytime
- No forced Plan Mode usage
- Major workflow Step 2-5 works independently

## Success Indicators

The guide is effective if:
- ✅ Users understand how to enter Plan Mode (Shift+Tab)
- ✅ Users know what to request from Claude in Plan Mode
- ✅ Users understand the connection between Plan Mode and /major
- ✅ Users feel comfortable choosing either option

## Notes

**Design Philosophy:**
- Keep instructions simple (3-4 steps maximum)
- Use emojis sparingly for visual guidance
- Provide concrete example prompts
- Always offer escape hatch (Option 2)
- Focus on "what to do" not "how it works"

**Future Improvements:**
- A/B test different message formats
- Collect user feedback on clarity
- Add animated GIF/video tutorial link
- Personalize based on user expertise level
