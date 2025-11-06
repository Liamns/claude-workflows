# Contributing to Claude Workflows

Thank you for your interest in contributing to Claude Workflows! This guide will help you get started.

## 🎯 Quick Start

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-workflow`)
3. Make your changes
4. Test thoroughly
5. Commit using `/commit` command (if you have Claude Code)
6. Push and create a Pull Request

## 📋 What We're Looking For

### Priority Contributions

- 🆕 **New Sub-agents** for specialized tasks
- 🛠 **New Skills** for common patterns
- 📚 **Documentation** improvements
- 🐛 **Bug fixes** in existing workflows
- 🌍 **Internationalization** support
- ⚡ **Performance** optimizations

### Project-Specific Workflows

We especially welcome workflows for:
- Vue.js projects
- Python/Django
- Mobile (React Native, Flutter)
- Backend frameworks (NestJS, Express)
- Different architectures (MVC, Clean Architecture)

## 🏗️ Development Setup

### Prerequisites

```bash
# Required
- Git
- Node.js 18+
- Claude Code access

# Optional
- Docker (for testing)
- GitHub CLI (for PR workflow)
```

### Local Development

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/claude-workflows
cd claude-workflows

# Install in test project
./install.sh ~/test-project

# Test your changes
cd ~/test-project
/your-new-command
```

## 📝 Creating a New Workflow

### 1. Command File Structure

Create `.claude/commands/your-workflow.md`:

```markdown
---
name: your-workflow
description: Brief description of what this workflow does
---

# Your Workflow Name

Detailed description and usage instructions.

## Usage

\`\`\`bash
/your-workflow [arguments]
\`\`\`

## Process

1. Step one
2. Step two
3. Step three

## Examples

[Include practical examples]
```

### 2. Workflow Implementation

```typescript
// Key components to define

interface WorkflowConfig {
  complexity: 'micro' | 'minor' | 'major';
  gates: QualityGate[];
  agents?: string[];
  skills?: string[];
}

const yourWorkflow: WorkflowConfig = {
  complexity: 'minor',
  gates: [
    { name: 'type-check', required: true },
    { name: 'tests', required: false }
  ],
  agents: ['your-agent'],
  skills: ['your-skill']
};
```

### 3. Add to Triage System

Update triage scoring in `.claude/commands/triage.md`:

```typescript
// Add your workflow keywords
const yourWorkflowKeywords = ['keyword1', 'keyword2'];

// Add to scoring logic
if (matchesYourWorkflow(request)) {
  return { workflow: 'your-workflow', score: X };
}
```

## 🤖 Creating a New Sub-agent

### Agent Template

Create `.claude/agents/your-agent.md`:

```markdown
---
name: your-agent
description: What this agent specializes in
tools: Bash, Read, Write, Edit, Grep
model: haiku  # or sonnet/opus
---

# Your Agent Name

You are a specialized agent for [specific task].

## Core Responsibilities

1. First responsibility
2. Second responsibility
3. Third responsibility

## Process

### Step 1: Analysis
[Detailed instructions]

### Step 2: Implementation
[Detailed instructions]

### Step 3: Validation
[Detailed instructions]

## Examples

[Provide examples of input/output]

## Quality Checks

- [ ] Check 1
- [ ] Check 2
- [ ] Check 3
```

### Agent Best Practices

1. **Single Responsibility**: Each agent should do one thing well
2. **Clear Instructions**: Be explicit about process and expectations
3. **Tool Selection**: Only request necessary tools
4. **Model Choice**: Use Haiku for simple tasks, Sonnet for complex
5. **Error Handling**: Include fallback strategies

## 🛠 Creating a New Skill

### Skill Structure

```
.claude/skills/your-skill/
├── SKILL.md           # Main skill definition
├── templates/         # Code templates
├── examples/          # Usage examples
└── reference/         # Additional documentation
```

### SKILL.md Template

```markdown
---
name: your-skill
description: Brief description
allowed-tools: Read, Write, Edit
---

# Your Skill Name

## Activation Triggers

- Condition 1 (e.g., specific file pattern)
- Condition 2 (e.g., error type)
- Condition 3 (e.g., import detection)

## Process

1. Detection phase
2. Analysis phase
3. Implementation phase
4. Validation phase

## Patterns

### Pattern 1: [Name]
\`\`\`typescript
// Before
[problematic code]

// After
[fixed code]
\`\`\`

## Integration

Automatically activated when:
- Working with [specific files]
- Detecting [specific patterns]
- User requests [specific actions]
```

## 🧪 Testing

### Manual Testing Checklist

- [ ] Command executes without errors
- [ ] Produces expected output
- [ ] Handles edge cases gracefully
- [ ] Token usage is optimized
- [ ] Quality gates pass
- [ ] Documentation is clear

### Test Scenarios

```bash
# Test basic functionality
/your-workflow test-input

# Test error handling
/your-workflow invalid-input

# Test with real project
cd real-project
/your-workflow production-case
```

### Creating Test Cases

Add to `tests/workflows/your-workflow.test.md`:

```markdown
# Test: Your Workflow

## Scenario 1: Basic Usage
Input: [input]
Expected: [output]
Result: [PASS/FAIL]

## Scenario 2: Edge Case
Input: [input]
Expected: [output]
Result: [PASS/FAIL]
```

## 📊 Performance Guidelines

### Token Optimization

- **Micro workflows**: < 1000 tokens total
- **Minor workflows**: < 5000 tokens total
- **Major workflows**: < 20000 tokens total

### Caching Strategy

```typescript
// Use caching for repeated operations
const cache = new Map();

function expensiveOperation(input: string) {
  if (cache.has(input)) {
    return cache.get(input);
  }

  const result = performOperation(input);
  cache.set(input, result);
  return result;
}
```

### Parallel Execution

```typescript
// Good: Parallel execution
const [a, b, c] = await Promise.all([
  taskA(),
  taskB(),
  taskC()
]);

// Bad: Sequential execution
const a = await taskA();
const b = await taskB();
const c = await taskC();
```

## 📚 Documentation Standards

### Code Comments

```typescript
/**
 * Brief description of what this does
 * @param input - What the parameter represents
 * @returns What the function returns
 * @example
 * const result = yourFunction('input');
 */
function yourFunction(input: string): string {
  // Inline comments for complex logic
  return processInput(input);
}
```

### Markdown Format

- Use clear headings (##, ###, ####)
- Include code examples with syntax highlighting
- Add emoji for visual organization (sparingly)
- Keep line length under 100 characters
- Use tables for structured data

## 🚀 Submitting a Pull Request

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] New workflow
- [ ] New sub-agent
- [ ] New skill
- [ ] Bug fix
- [ ] Documentation
- [ ] Performance improvement

## Testing
- [ ] Tested locally
- [ ] Added test cases
- [ ] Documentation updated

## Screenshots (if applicable)
[Add screenshots]

## Notes
[Any additional notes]
```

### PR Checklist

- [ ] Code follows project style
- [ ] Self-review completed
- [ ] Documentation added/updated
- [ ] Tests pass
- [ ] No sensitive data exposed
- [ ] Changelog updated (for significant changes)

## 🤝 Code Review Process

### What We Look For

1. **Functionality**: Does it work as intended?
2. **Performance**: Is it efficient?
3. **Maintainability**: Is it easy to understand?
4. **Documentation**: Is it well-documented?
5. **Testing**: Is it properly tested?

### Review Timeline

- **Initial review**: Within 48 hours
- **Feedback incorporation**: Author's pace
- **Final review**: Within 24 hours of updates
- **Merge**: After approval from maintainer

## 💬 Communication

### Getting Help

- **Discord**: [Join our server](https://discord.gg/claude-workflows)
- **Issues**: [GitHub Issues](https://github.com/Liamns/claude-workflows/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Liamns/claude-workflows/discussions)

### Reporting Issues

```markdown
## Issue Template

**Description**
Clear description of the issue

**Steps to Reproduce**
1. Step one
2. Step two
3. Step three

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- OS: [e.g., macOS 14.0]
- Node: [e.g., 18.0.0]
- Claude Code: [version]

**Additional Context**
Any other relevant information
```

## 🏆 Recognition

Contributors are recognized in:
- README.md contributors section
- CHANGELOG.md for significant contributions
- Special badges for regular contributors
- Annual contributor spotlight

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Claude Workflows! Your efforts help make development with Claude Code better for everyone. 🙌