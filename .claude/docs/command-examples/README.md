# Command Examples

이 디렉토리는 슬래시 명령어의 예시 및 트러블슈팅 문서를 포함합니다.

## 파일 구조

- `{command}-examples.md`: 명령어 사용 예시
- `{command}-document-templates.md`: 문서 템플릿
- `{command}-troubleshooting.md`: 트러블슈팅 가이드

## 참조하는 명령어

- [plan-major.md](../../commands/plan-major.md) - Major 계획 수립
- [plan-minor.md](../../commands/plan-minor.md) - Minor 계획 수립
- [implement.md](../../commands/implement.md) - 구현 단계
- [micro.md](../../commands/micro.md) - Micro 워크플로우

## 포함된 파일

### Major 워크플로우
- `major-examples.md` - Major 워크플로우 사용 예시
- `major-document-templates.md` - Major 문서 템플릿
- `major-troubleshooting.md` - Major 트러블슈팅 가이드

### Minor 워크플로우
- `minor-examples.md` - Minor 워크플로우 사용 예시
- `minor-document-templates.md` - Minor 문서 템플릿
- `minor-troubleshooting.md` - Minor 트러블슈팅 가이드

### Micro 워크플로우
- `micro-examples.md` - Micro 워크플로우 사용 예시
- `micro-troubleshooting.md` - Micro 트러블슈팅 가이드

## 사용 방법

각 명령어 파일에서 이 디렉토리의 예시 파일을 참조합니다:

```markdown
자세한 사용 예시는 [major-examples.md](../docs/command-examples/major-examples.md)를 참고하세요.
```

## 워크플로우 구조

```
Major: /plan-major → /implement (2단계)
Minor: /plan-minor → /implement (2단계)
Micro: /micro (단일 단계)
```
