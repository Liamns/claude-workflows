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
- Major workflow commands changed: Use `/major` instead of individual `major-*` commands
- Agent names changed: e.g., `architect` → `architect-unified`
- File paths changed: Root `agents/` and `skills/` folders removed, use `.claude/` paths

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

### From 1.0.0 to 2.0.0

1. **Update installation**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
   ```

2. **New commands available**:
   - Use `/triage` instead of manually selecting workflows
   - Use `/commit` for automatic commit messages
   - Use `/pr-review` for PR analysis

3. **No breaking changes** - All v1.0 commands still work

### From 0.1.0 to 1.0.0

Complete reinstallation recommended:
```bash
rm -rf .claude .specify
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
/start
```