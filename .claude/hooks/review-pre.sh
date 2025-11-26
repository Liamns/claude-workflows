#!/bin/bash
# PreHook: /review 명령어 옵션 검증
# Exit codes: 0=통과, 2=차단

set -e

echo "" >&2
echo "🔍 /review PreHook 실행 중..." >&2

# 인자 파싱 (Claude Code Hook은 환경변수로 전달받음)
ARGS="${CLAUDE_COMMAND_ARGS:-}"

# 1. --adv 옵션 검증
if [[ "$ARGS" == *"--adv"* ]]; then
    echo "   ℹ️  고급 리뷰 모드 (--adv) 감지" >&2

    # npm 설치 여부 확인 (npm audit 사용을 위해)
    if ! command -v npm &> /dev/null; then
        echo "" >&2
        echo "⚠️  [경고] npm이 설치되어 있지 않습니다." >&2
        echo "   --adv 옵션의 일부 기능(npm audit)이 제한될 수 있습니다." >&2
        # 경고만 출력, 차단하지 않음
    else
        echo "   ✓ npm 설치 확인됨" >&2
    fi
fi

# 2. --arch 옵션 검증
if [[ "$ARGS" == *"--arch"* ]]; then
    echo "   ℹ️  아키텍처 리뷰 모드 (--arch) 감지" >&2

    # architecture.json 존재 확인
    if [[ ! -f ".specify/config/architecture.json" ]]; then
        echo "" >&2
        echo "⚠️  [경고] architecture.json이 없습니다." >&2
        echo "   /start 명령어로 프로젝트를 먼저 초기화하세요." >&2
        # 경고만 출력, 차단하지 않음
    else
        echo "   ✓ architecture.json 존재 확인됨" >&2
    fi
fi

# 3. --staged 옵션 검증
if [[ "$ARGS" == *"--staged"* ]]; then
    echo "   ℹ️  스테이징된 파일 리뷰 모드 (--staged) 감지" >&2

    # Git 저장소 확인
    if ! git rev-parse --git-dir &> /dev/null 2>&1; then
        echo "" >&2
        echo "❌ [차단] Git 저장소가 아닙니다." >&2
        echo "   --staged 옵션은 Git 저장소에서만 사용할 수 있습니다." >&2
        exit 2
    fi

    # 스테이징된 파일 존재 확인
    if [[ -z "$(git diff --cached --name-only 2>/dev/null)" ]]; then
        echo "" >&2
        echo "⚠️  [경고] 스테이징된 파일이 없습니다." >&2
        echo "   git add로 파일을 스테이징한 후 다시 시도하세요." >&2
        # 경고만 출력, 차단하지 않음
    else
        echo "   ✓ 스테이징된 파일 존재 확인됨" >&2
    fi
fi

# 4. 경로 인자 검증 (옵션이 아닌 마지막 인자)
PATH_ARG=""
for arg in $ARGS; do
    if [[ "$arg" != --* && -n "$arg" ]]; then
        PATH_ARG="$arg"
    fi
done

if [[ -n "$PATH_ARG" ]]; then
    if [[ ! -e "$PATH_ARG" ]]; then
        echo "" >&2
        echo "❌ [차단] 지정된 경로가 존재하지 않습니다: $PATH_ARG" >&2
        exit 2
    else
        echo "   ✓ 리뷰 대상 경로 확인됨: $PATH_ARG" >&2
    fi
fi

echo "" >&2
echo "✅ PreHook 검증 통과" >&2

# 통과
exit 0
