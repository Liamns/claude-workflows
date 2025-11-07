# /major-specify - Specification 생성 (Step 1/4)

Feature의 WHAT/WHY만 정의하는 비기술적 명세서를 생성합니다.

## 사용법

```
/major-specify [feature-name]
```

## 실행 내용

`/major`의 1-3단계를 독립적으로 실행:
1. Feature 브랜치 생성
2. Interactive 질문을 통한 spec.md 생성
3. spec.md 저장

## 생성 파일

```
.specify/specs/NNN-feature-name/
└── spec.md  ✅
```

## 다음 단계

```
/major-clarify    # 모호한 부분 질문 (선택)
/major-plan       # 기술 계획 수립
```
