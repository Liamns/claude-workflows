# Quickstart: Installation Verification Improvement

> 이 문서는 spec.md의 시나리오와 data-model.md의 구조를 기반으로 작성되었습니다.
> 참조: [spec.md](./spec.md), [data-model.md](./data-model.md)

## Prerequisites

- [ ] Bash 3.2+ installed (macOS default: 3.2.57)
- [ ] Git installed
- [ ] SHA256 checksum tool available:
  - macOS: `shasum` (pre-installed)
  - Linux: `sha256sum` (pre-installed)
  - Fallback: `openssl dgst -sha256`
- [ ] File download tool available:
  - macOS: `curl` (pre-installed)
  - Linux: `wget` or `curl`
- [ ] Internet connection for GitHub access
- [ ] Write permissions in project directory

## Data Model Overview (from data-model.md)

이 기능은 다음 Entities를 사용합니다:

1. **FileVerificationResult**: 각 파일의 검증 결과 (체크섬, 상태, 재시도 횟수)
2. **ChecksumManifest**: 설치 버전별 체크섬 매니페스트 (.claude/.checksums.json)
3. **GitignorePattern**: .gitignore에 추가할 패턴 (백업, 캐시, 로그 등)

## Setup Steps

### 1. Verify Prerequisites

**Check SHA256 tool**:
```bash
# macOS
shasum -a 256 --version

# Linux
sha256sum --version

# Fallback
openssl version
```

**Check download tool**:
```bash
# Preferred
curl --version

# Alternative
wget --version
```

### 2. Generate Checksum Manifest (개발자용)

기능 구현 후, GitHub 저장소에 체크섬 매니페스트를 생성합니다:

```bash
# 매니페스트 생성 스크립트 실행
bash .claude/lib/generate-checksums.sh > .claude/.checksums.json

# 생성된 매니페스트 확인
cat .claude/.checksums.json
```

**Expected output**:
```json
{
  "version": "2.6.0",
  "generatedAt": "2025-01-11T10:00:00Z",
  "files": {
    ".claude/commands/major.md": "a1b2c3d4e5f6...",
    ".claude/lib/cache-helper.sh": "b2c3d4e5f6a7...",
    ...
  }
}
```

### 3. Test Installation with Verification

**Option A: Fresh Install (권장)**
```bash
# 설치 스크립트 실행 (개선된 검증 포함)
bash install.sh

# 설치 과정 모니터링:
# 1. 파일 복사 완료
# 2. 체크섬 매니페스트 다운로드
# 3. 각 파일 검증 중...
# 4. 불일치 파일 감지 시 자동 재다운로드
# 5. .gitignore 자동 업데이트
# 6. 검증 완료 보고
```

**Option B: Existing Install (업그레이드)**
```bash
# 기존 설치에서 업그레이드
bash install.sh

# 백업 자동 생성됨:
# .claude/.backup/install-YYYYMMDD-HHMMSS/
```

### 4. Verify Results

**Check verification report**:
```bash
# 설치 로그 확인
cat .claude/.backup/install-*.log | grep -A 10 "verification"
```

**Check .gitignore**:
```bash
# .gitignore에 패턴이 추가되었는지 확인
cat .gitignore

# 예상 패턴:
# .claude/.backup/
# .claude/cache/
# *.log
```

**Check Git status**:
```bash
# Git 상태가 깨끗한지 확인 (추적되지 않은 파일 0개)
git status

# Expected:
# nothing to commit, working tree clean
```

## Verification Scenarios (from spec.md User Scenarios)

### Scenario 1: Normal Installation (All Files Pass)

**Given**: 깨끗한 프로젝트 디렉토리
**When**: `bash install.sh` 실행
**Then**: 모든 파일이 체크섬 검증 통과

**Steps**:
1. Run installation:
   ```bash
   bash install.sh
   ```

2. **Expected output**:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   File Verification (SHA256)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✓ .claude/commands/major.md ... PASS
   ✓ .claude/lib/cache-helper.sh ... PASS
   ...
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✅ All files verified (50/50)
   ```

3. **Verify**:
   - [ ] All files show "PASS"
   - [ ] No retry messages
   - [ ] .gitignore updated
   - [ ] `git status` clean

**Expected result**:
✅ 설치 성공률: 100%, 파일 무결성: 100%

### Scenario 2: File Mismatch with Automatic Recovery

**Given**: 일부 파일이 손상되거나 불완전하게 복사됨
**When**: 설치 검증 실행
**Then**: 불일치 파일 자동 재다운로드 및 복구

**Steps**:
1. **Simulate corruption** (테스트용):
   ```bash
   # 설치 후 파일 수정하여 불일치 시뮬레이션
   echo "corrupted" >> .claude/commands/major.md
   ```

2. **Run verification manually**:
   ```bash
   bash .claude/lib/verify-with-checksum.sh
   ```

3. **Expected output**:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   File Verification (SHA256)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✓ .claude/lib/cache-helper.sh ... PASS
   ✗ .claude/commands/major.md ... FAIL

   ⚠️ Found 1 file(s) with checksum mismatch

   Retrying failed files...
   ↓ Downloading .claude/commands/major.md (attempt 1/3)
   ✓ .claude/commands/major.md ... PASS (re-verified)

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✅ All files verified after retry (50/50)
   ```

4. **Verify**:
   - [ ] 불일치 파일이 감지됨
   - [ ] 자동 재다운로드 시도
   - [ ] 재검증 통과
   - [ ] 최종적으로 모든 파일 통과

**Expected result**:
✅ 재다운로드 성공률: 95% 이상

### Scenario 3: .gitignore Auto-Management

**Given**: 설치 프로세스 실행
**When**: 백업 및 캐시 파일 생성
**Then**: .gitignore에 패턴 자동 추가

**Steps**:
1. **Check .gitignore before installation**:
   ```bash
   cat .gitignore  # (may not exist)
   ```

2. **Run installation**:
   ```bash
   bash install.sh
   ```

3. **Check .gitignore after installation**:
   ```bash
   cat .gitignore

   # Expected contents:
   # Claude Workflows Installer - Auto-generated
   .claude/.backup/
   .claude/cache/
   *.log
   *.tmp
   .DS_Store
   ```

4. **Verify Git status**:
   ```bash
   git status

   # Expected:
   # On branch main
   # Changes not staged for commit:
   #   modified:   .gitignore    (only this file)
   #
   # Untracked files: (none)
   ```

5. **Test duplicate prevention**:
   ```bash
   # 설치를 다시 실행
   bash install.sh

   # .gitignore 확인 - 중복 패턴 없어야 함
   cat .gitignore | sort | uniq -c
   # (모든 패턴의 count가 1이어야 함)
   ```

**Expected result**:
✅ 설치 후 git status에서 추적되지 않은 파일 0개

## Troubleshooting

### Issue: "No SHA256 tool found"
**Symptoms**:
```
ERROR: No SHA256 tool found (shasum, sha256sum, or openssl)
```

**Solution**:
```bash
# macOS: shasum은 기본 제공됨
which shasum  # /usr/bin/shasum

# Linux: coreutils 설치
sudo apt-get install coreutils   # Ubuntu/Debian
sudo yum install coreutils        # CentOS/RHEL

# Fallback: openssl 사용
which openssl  # 대부분 기본 설치됨
```

### Issue: "Download failed after 3 attempts"
**Symptoms**:
```
ERROR: Failed to download .claude/commands/major.md after 3 attempts
```

**Solution**:
1. **Check internet connection**:
   ```bash
   ping github.com
   ```

2. **Check GitHub access**:
   ```bash
   curl -I https://raw.githubusercontent.com/Liamns/claude-workflows/main/README.md
   ```

3. **Manual download**:
   ```bash
   # 실패한 파일을 수동으로 다운로드
   curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/.claude/commands/major.md \
     -o .claude/commands/major.md
   ```

4. **Re-run verification**:
   ```bash
   bash .claude/lib/verify-with-checksum.sh
   ```

### Issue: "Checksum manifest not found"
**Symptoms**:
```
ERROR: Checksum manifest not found: .claude/.checksums.json
```

**Solution**:
```bash
# 1. 매니페스트가 GitHub 저장소에 포함되어 있는지 확인
curl -I https://raw.githubusercontent.com/Liamns/claude-workflows/main/.claude/.checksums.json

# 2. 수동으로 다운로드
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/.claude/.checksums.json \
  -o .claude/.checksums.json

# 3. 다시 설치 실행
bash install.sh
```

### Issue: ".gitignore patterns not added"
**Symptoms**:
```
git status shows many untracked files (.claude/.backup/, *.log, etc.)
```

**Solution**:
```bash
# 수동으로 패턴 추가
source .claude/lib/gitignore-manager.sh
add_installer_patterns_to_gitignore

# 또는 직접 편집
cat >> .gitignore << 'EOF'
.claude/.backup/
.claude/cache/
*.log
*.tmp
.DS_Store
EOF

# Git 상태 재확인
git status
```

## Performance Benchmarks

Based on research.md findings:

| Operation | Files | Time | Notes |
|-----------|-------|------|-------|
| SHA256 checksum (single file) | 1 (10KB) | ~10ms | SSD |
| SHA256 checksum (all files) | 50 | ~0.5s | Sequential |
| SHA256 checksum (parallel) | 50 | ~0.2s | 4 workers |
| File download (single) | 1 (10KB) | ~0.5s | Network latency |
| File download (retry) | 5 | ~2.5s | Sequential |

**Expected total time**:
- Normal install (all pass): **~1s** verification
- With retry (5 files): **~3s** verification + retry

## Next Steps

After successful installation and verification:

1. **Commit .gitignore changes**:
   ```bash
   git add .gitignore
   git commit -m "chore: update .gitignore with installer patterns"
   ```

2. **Verify workflow functionality**:
   ```bash
   # Test basic commands
   # (Claude Code에서 실행)
   /start
   /triage "test"
   ```

3. **Review installation log**:
   ```bash
   cat .claude/.backup/install-*.log
   ```

4. **Check documentation**:
   - Read `.claude/docs/PROJECT-CONTEXT.md`
   - Review workflow guides

## References

- [spec.md](./spec.md) - Full specification
- [data-model.md](./data-model.md) - Data structures
- [research.md](./research.md) - Implementation research
- [GitHub Repository](https://github.com/Liamns/claude-workflows)
