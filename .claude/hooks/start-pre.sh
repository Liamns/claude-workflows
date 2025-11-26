#!/bin/bash
# PreHook: /start 명령어 중복 초기화 방지
# Exit codes: 0=통과, 2=차단

set -e

echo "" >&2
echo "🔍 /start PreHook 실행 중..." >&2

# 1. .specify/ 디렉토리 존재 확인
if [[ -d ".specify" ]]; then
    echo "" >&2
    echo "⚠️  [경고] 이미 초기화된 프로젝트입니다." >&2
    echo "   .specify/ 디렉토리가 존재합니다." >&2

    # constitution.md 존재 확인
    if [[ -f ".specify/memory/constitution.md" ]]; then
        echo "   constitution.md가 이미 존재합니다." >&2
    fi

    # architecture.json 존재 확인
    if [[ -f ".specify/config/architecture.json" ]]; then
        echo "   architecture.json이 이미 존재합니다." >&2
    fi

    echo "" >&2
    echo "💡 재초기화를 원하면 기존 설정을 먼저 백업/삭제하세요:" >&2
    echo "   rm -rf .specify/" >&2
    echo "" >&2
    # 경고만 출력, 차단하지 않음 (재초기화 허용)
else
    echo "   ✓ 신규 프로젝트 확인됨" >&2
fi

# 2. .claude/ 디렉토리 확인 (Claude Workflow 디렉토리)
if [[ -d ".claude" && -f ".claude/settings.json" ]]; then
    echo "   ✓ Claude 설정 디렉토리 존재 확인됨" >&2
fi

# 3. 프로젝트 루트 파일 확인
project_type="unknown"

if [[ -f "package.json" ]]; then
    project_type="Node.js"
    echo "   ✓ package.json 감지됨 (Node.js 프로젝트)" >&2
elif [[ -f "requirements.txt" || -f "pyproject.toml" ]]; then
    project_type="Python"
    echo "   ✓ Python 프로젝트 감지됨" >&2
elif [[ -f "go.mod" ]]; then
    project_type="Go"
    echo "   ✓ go.mod 감지됨 (Go 프로젝트)" >&2
elif [[ -f "Cargo.toml" ]]; then
    project_type="Rust"
    echo "   ✓ Cargo.toml 감지됨 (Rust 프로젝트)" >&2
elif [[ -f "pom.xml" || -f "build.gradle" ]]; then
    project_type="Java"
    echo "   ✓ Java 프로젝트 감지됨" >&2
else
    echo "   ℹ️  표준 프로젝트 파일이 감지되지 않았습니다." >&2
    echo "      아키텍처 감지가 제한될 수 있습니다." >&2
fi

# 4. Git 저장소 확인
if git rev-parse --git-dir &> /dev/null 2>&1; then
    echo "   ✓ Git 저장소 확인됨" >&2
else
    echo "   ℹ️  Git 저장소가 아닙니다. git init 권장" >&2
fi

echo "" >&2
echo "✅ PreHook 검증 통과" >&2

# 통과
exit 0
