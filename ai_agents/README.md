# AI Agents Directory

This directory contains AI agent configurations, memories, and rules.

## Structure

- **memories/** - AI agent memories and learnings
- **rules/** - Rules and guidelines for AI agents
- **crews/** - CrewAI crew configurations

## Usage

### Saving Memories

Use the GitHub Actions workflow `save-ai-memory.yml` to save AI agent memories:

```bash
gh workflow run save-ai-memory.yml -f memory_name="example_memory" -f content="Memory content here"
```

Or manually create a file in the `memories/` directory:

```bash
echo "Memory content" > ai_agents/memories/my_memory_$(date +%Y%m%d_%H%M%S).md
```

### Saving Rules

Use the GitHub Actions workflow `save-ai-rule.yml` to save AI agent rules:

```bash
gh workflow run save-ai-rule.yml -f rule_name="example_rule" -f content="Rule content here"
```

Or manually create a file in the `rules/` directory:

```bash
echo "Rule content" > ai_agents/rules/my_rule.md
```

### Managing Crews

Store CrewAI crew configurations in the `crews/` directory. Each crew should have its own subdirectory with relevant configuration files.

## Automation

The repository includes automated workflows for:
- Saving memories with timestamps
- Saving and updating rules
- Managing crew configurations
- Recalling and searching stored information
