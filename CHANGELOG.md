# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.5.0] - 2025-11-07

### Added 🆕
- **📊 Real-time Metrics Dashboard** (`/dashboard` command)
  - Live workflow performance monitoring
  - Token usage tracking with savings calculation
  - Performance metrics (execution time, cache hit rate, parallel processing)
  - Quality indicators (test coverage, type check, lint results)
  - Productivity tracking (tasks, bugs, features)
  - Git integration (commits, changes, branch status)
- **Metrics Collection System**
  - `git-stats-helper.sh` - Git statistics collector
  - `metrics-collector.sh` - Core metrics collection functions
  - `dashboard-generator.sh` - Terminal dashboard renderer with colors
  - JSON-based metrics storage (current session, daily, summary)
  - Three view modes: `--current`, `--today`, `--summary`

### Enhanced ✨
- Integrated metrics collection with cache-helper.sh
- Beautiful ASCII dashboard with colors and emojis
- Automatic Git statistics tracking
- Session-based metric persistence

### Infrastructure 🏗️
- `.claude/cache/metrics/` - Metrics data storage
- `.claude/cache/workflow-history/` - Workflow execution history
- Metrics JSON schemas for structured data

## [2.4.0] - 2025-11-07

### Added 🆕
- `/test` command - Smart test workflow with automated test generation and execution
- **Unified agents** - New consolidated agents for better performance:
  - `architect-unified` - All architecture pattern validation (FSD, Clean, Hexagonal, DDD, etc.)
  - `reviewer-unified` - Comprehensive code review (quality, security, performance, impact)
  - `implementer-unified` - TDD-based implementation and bug fixing
  - `documenter-unified` - Commit messages and changelog documentation

### Changed 🔄
- **Major workflow consolidation**: 6 commands → 1 unified `/major` command
- **Question reduction**: 10 questions → 2 essential questions only
- **State management**: Added automatic save/resume for Major workflow
- **Agent consolidation**: 11 agents → 6 agents (45% reduction)
- **Command reduction**: 16 commands → 10 commands (38% reduction)
- **README optimization**: 395 lines → 104 lines (74% reduction)

### Removed 🗑️
- Individual major commands (`major-specify`, `major-clarify`, `major-plan`, `major-tasks`, `major-implement`)
- Duplicate folders (`agents/`, `skills/` at root level)
- Redundant agents (separate `architect`, `fsd-architect`, `code-reviewer`, etc.)
- `workflow-gates-v2.json` (consolidated into single version)

### Fixed 🐛
- triage.md: Replaced `[Enter]` key input with `AskUserQuestion` tool for Claude Code compatibility
- Registry.json: Clearly marked implemented vs planned architectures
- File structure: Applied single source principle, removed all duplications

### Breaking Changes 💥

#### 🚨 IMPORTANT: v2.4.0 contains significant breaking changes

**Removed Commands** (5 files):
- ❌ `.claude/commands/major-specify.md` → Use `/major` instead
- ❌ `.claude/commands/major-clarify.md` → Use `/major` instead
- ❌ `.claude/commands/major-plan.md` → Use `/major` instead
- ❌ `.claude/commands/major-tasks.md` → Use `/major` instead
- ❌ `.claude/commands/major-implement.md` → Use `/major` instead

**Removed Agents** (8 files):
- ❌ `.claude/agents/architect.md` → Use `architect-unified.md`
- ❌ `.claude/agents/fsd-architect.md` → Merged into `architect-unified.md`
- ❌ `.claude/agents/code-reviewer.md` → Use `reviewer-unified.md`
- ❌ `.claude/agents/security-scanner.md` → Merged into `reviewer-unified.md`
- ❌ `.claude/agents/impact-analyzer.md` → Merged into `reviewer-unified.md`
- ❌ `.claude/agents/quick-fixer.md` → Use `implementer-unified.md`
- ❌ `.claude/agents/test-guardian.md` → Merged into `implementer-unified.md`
- ❌ `.claude/agents/smart-committer.md` → Use `documenter-unified.md`
- ❌ `.claude/agents/changelog-writer.md` → Merged into `documenter-unified.md`

**Agent Mapping** (Old → New):
| Old Agent | New Agent | Notes |
|-----------|-----------|-------|
| `architect` | `architect-unified` | All architecture patterns supported |
| `fsd-architect` | `architect-unified` | FSD logic merged |
| `code-reviewer` | `reviewer-unified` | Security & performance included |
| `security-scanner` | `reviewer-unified` | Merged |
| `impact-analyzer` | `reviewer-unified` | Merged |
| `quick-fixer` | `implementer-unified` | Bug fixes & TDD |
| `test-guardian` | `implementer-unified` | TDD logic merged |
| `smart-committer` | `documenter-unified` | Git operations |
| `changelog-writer` | `documenter-unified` | Notion integration |

**File Structure Changes**:
- ❌ Root level `agents/` folder removed → Use `.claude/agents/`
- ❌ Root level `skills/` folder removed → Use `.claude/skills/`
- ❌ `workflow-gates-v2.json` removed → Use `workflow-gates.json`

**Configuration Changes**:
- `workflow-gates.json` format updated for v2.4.0
- Old v1.0 format is incompatible

## [2.3.0] - 2025-01-07

### Added 🆕
- `/review` command - Comprehensive code review system
- Multi-architecture support (12 patterns)
- Model optimization (Opus/Sonnet/Haiku auto-switching)
- Context7 integration

## [2.0.0] - 2025-01-06

### Added 🆕
- `/triage` command - Automatic workflow selection based on task complexity (75-85% token savings)
- `/commit` command - Smart conventional commits with automatic type detection
- `/pr-review` command - Automated GitHub PR review with security and performance checks
- `smart-committer` agent - Intelligent commit message generation with breaking changes detection
- `commit-guard` skill - Pre-commit validation with 3 levels (Quick, Standard, Full)
- Comprehensive documentation:
  - `SUB-AGENTS-GUIDE.md` - Detailed guide for all sub-agents
  - `SKILLS-GUIDE.md` - Complete skills system documentation
  - `IMPROVEMENT-PROPOSALS.md` - Future enhancement roadmap

### Enhanced ✨
- `code-reviewer` agent - Added GitHub CLI integration for PR operations
- `install.sh` - Updated for new commands and documentation
- README.md - Complete restructure with new features showcase

### Improved 📈
- **Token efficiency**: 60% → up to 85% reduction
- **Development speed**: 2.5x → 3x improvement
- **Quality assurance**: Automated validation at every step

## [1.0.0] - 2024-12-01

### Added
- Major workflow with spec-kit integration
- Minor workflow for bug fixes and improvements
- Micro workflow for quick changes
- 7 Sub-agents:
  - `quick-fixer` - Fast bug fixes
  - `changelog-writer` - Git to Notion documentation
  - `fsd-architect` - FSD architecture validation
  - `test-guardian` - TDD enforcement
  - `api-designer` - API contract design
  - `mobile-specialist` - Capacitor platform handling
  - `code-reviewer` - Security and performance review
- 7 Skills:
  - `bug-fix-pattern` - Common bug fix patterns
  - `daily-changelog-notion` - Notion changelog automation
  - `fsd-component-creation` - FSD component templates
  - `api-integration` - httpClient patterns
  - `form-validation` - React Hook Form + Zod
  - `platform-detection` - Platform-specific rendering
  - `mobile-build` - Android/iOS build automation
- `workflow-gates.json` - Quality gate configuration
- `/start` command for project initialization

### Infrastructure
- `.specify/` directory structure for spec-kit
- `.claude/` directory for workflows
- Installation script for easy setup

## [0.1.0] - 2024-11-01

### Initial Release
- Basic workflow structure
- Proof of concept for sub-agents
- Initial skill system

---

## Upgrade Guide

### 🚀 Automatic Upgrade (v2.5.0+)

The installer now supports automatic version detection and migration:

```bash
# Automatically detects existing version and runs migration
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

**What happens automatically**:
1. ✅ Detects existing installation version
2. ✅ Creates backup in `.claude/.backup/install-YYYYMMDD-HHMMSS/`
3. ✅ Runs appropriate migration scripts
4. ✅ Removes deprecated files
5. ✅ Updates configuration files
6. ✅ Preserves user customizations

---

### From v2.4.x to v2.5.0

**Changes**:
- New metrics dashboard system (`/dashboard`)
- New directory structure for metrics tracking
- Enhanced workflow history

**Automatic Migration**:
```bash
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

**What gets migrated**:
- ✅ Creates `.claude/cache/metrics/` directory structure
- ✅ Creates `.claude/cache/workflow-history/` directory
- ✅ Initializes metrics system
- ✅ Updates `workflow-gates.json` version to 2.5.0
- ✅ Backs up existing cache

**New features**:
```bash
/dashboard          # View current session metrics
/dashboard --today  # Today's statistics
/dashboard --summary # Full cumulative stats
```

---

### From v1.0.x to v2.5.0

**⚠️ IMPORTANT: v2.4.0+ contains breaking changes**

**Automatic Migration**:
```bash
# The installer will automatically:
# 1. Detect v1.0.x installation
# 2. Run v1→v2.4 migration
# 3. Run v2.4→v2.5 migration
# 4. Remove all deprecated files
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

**What gets removed automatically**:

**Commands** (5 files):
- `.claude/commands/major-specify.md` ❌
- `.claude/commands/major-clarify.md` ❌
- `.claude/commands/major-plan.md` ❌
- `.claude/commands/major-tasks.md` ❌
- `.claude/commands/major-implement.md` ❌

**Agents** (8 files):
- `.claude/agents/architect.md` ❌
- `.claude/agents/fsd-architect.md` ❌
- `.claude/agents/code-reviewer.md` ❌
- `.claude/agents/security-scanner.md` ❌
- `.claude/agents/impact-analyzer.md` ❌
- `.claude/agents/quick-fixer.md` ❌
- `.claude/agents/test-guardian.md` ❌
- `.claude/agents/smart-committer.md` ❌

**What gets backed up**:
- `workflow-gates.json` → `.claude/.backup/migration-YYYYMMDD-HHMMSS/`
- `.claude/config/` → `.claude/.backup/migration-YYYYMMDD-HHMMSS/`
- All deprecated files before deletion

**Command Changes**:
| Old Command | New Command | Notes |
|-------------|-------------|-------|
| `/major-specify` + 4 more | `/major` | Single unified command |
| N/A | `/dashboard` | New in v2.5.0 |

**Agent Changes**:
| Old Agent | New Agent | Notes |
|-----------|-----------|-------|
| `architect` | `architect-unified` | All architectures |
| `code-reviewer` | `reviewer-unified` | + security + performance |
| `quick-fixer` | `implementer-unified` | + TDD |
| `smart-committer` | `documenter-unified` | + changelog |

**After upgrade**:
```bash
# Test the new unified command
/major "implement user authentication"

# View metrics
/dashboard

# Continue using other commands as before
/triage
/commit
/review
```

---

### From v2.0.x to v2.5.0

**Changes**: v2.4.0 breaking changes + v2.5.0 metrics system

**Automatic Migration**:
```bash
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

Same process as v1.0.x → v2.5.0 upgrade.

---

### Manual Migration (if automatic fails)

If the automatic migration fails, follow these manual steps:

#### Step 1: Backup existing installation
```bash
cp -r .claude .claude.backup.$(date +%Y%m%d)
```

#### Step 2: Remove deprecated files manually
```bash
# Remove old major commands
rm -f .claude/commands/major-specify.md
rm -f .claude/commands/major-clarify.md
rm -f .claude/commands/major-plan.md
rm -f .claude/commands/major-tasks.md
rm -f .claude/commands/major-implement.md

# Remove old agents
rm -f .claude/agents/architect.md
rm -f .claude/agents/fsd-architect.md
rm -f .claude/agents/code-reviewer.md
rm -f .claude/agents/security-scanner.md
rm -f .claude/agents/impact-analyzer.md
rm -f .claude/agents/quick-fixer.md
rm -f .claude/agents/test-guardian.md
rm -f .claude/agents/smart-committer.md
rm -f .claude/agents/changelog-writer.md
```

#### Step 3: Install new version
```bash
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

#### Step 4: Verify installation
```bash
/major --help
/dashboard
```

---

### Rollback Procedure

If you need to rollback to a previous version:

#### Find your backup
```bash
ls -la .claude/.backup/
# or
ls -la .claude.backup.*
```

#### Restore from backup
```bash
# For automatic backups
cp -r .claude/.backup/install-YYYYMMDD-HHMMSS/* .claude/

# For manual backups
cp -r .claude.backup.YYYYMMDD/* .claude/
```

#### Reinstall specific version
```bash
# Clone specific version tag
git clone --branch v1.0.0 https://github.com/Liamns/claude-workflows
cd claude-workflows
bash install.sh /path/to/your/project
```

---

### From 0.1.0 to 2.5.0

Complete reinstallation recommended:
```bash
rm -rf .claude .specify
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
/start
```

---

### Troubleshooting

**Issue**: "Migration script not found"
**Solution**: The migration scripts are included in v2.5.0+. If you see this warning during install from older versions, the deprecated files will simply be overwritten rather than cleanly removed. No action needed.

**Issue**: "Deprecated commands still showing up"
**Solution**: Run manual cleanup:
```bash
bash .claude/lib/migrate-v1-to-v2.sh
```

**Issue**: "Old agents still being called"
**Solution**: Check your `.claude/commands/` files for references to old agent names and update them to unified names.

**Issue**: "Lost user customizations"
**Solution**: Restore from backup:
```bash
cp .claude/.backup/install-YYYYMMDD-HHMMSS/config/* .claude/config/
```