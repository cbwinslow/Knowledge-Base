# Code Analysis Tools

Tools for analyzing code quality, detecting bugs, and enforcing coding standards.

## Linters

### ESLint (JavaScript/TypeScript)
**Purpose:** JavaScript and TypeScript linting  
**Configuration:**
```yaml
tool:
  name: eslint
  type: linter
  languages: [javascript, typescript]
  config_file: .eslintrc.json
  command: eslint
  args:
    - "--ext"
    - ".js,.jsx,.ts,.tsx"
    - "--fix"
    - "."
  integration:
    - vscode
    - intellij
    - ci_cd
```

### Pylint (Python)
**Purpose:** Python code analysis  
**Configuration:**
```yaml
tool:
  name: pylint
  type: linter
  languages: [python]
  config_file: .pylintrc
  command: pylint
  args:
    - "--rcfile=.pylintrc"
    - "**/*.py"
  integration:
    - vscode
    - pycharm
    - ci_cd
```

### RuboCop (Ruby)
**Purpose:** Ruby code style checker  
**Configuration:**
```yaml
tool:
  name: rubocop
  type: linter
  languages: [ruby]
  config_file: .rubocop.yml
  command: rubocop
  args:
    - "--auto-correct"
  integration:
    - vscode
    - rubymine
    - ci_cd
```

### golangci-lint (Go)
**Purpose:** Go linters aggregator  
**Configuration:**
```yaml
tool:
  name: golangci-lint
  type: linter
  languages: [go]
  config_file: .golangci.yml
  command: golangci-lint
  args:
    - "run"
    - "--fix"
  integration:
    - vscode
    - goland
    - ci_cd
```

## Formatters

### Prettier
**Purpose:** Opinionated code formatter  
**Configuration:**
```yaml
tool:
  name: prettier
  type: formatter
  languages: [javascript, typescript, css, html, json, yaml, markdown]
  config_file: .prettierrc
  command: prettier
  args:
    - "--write"
    - "**/*.{js,jsx,ts,tsx,css,html,json,yaml,md}"
  integration:
    - vscode
    - intellij
    - pre_commit
```

### Black (Python)
**Purpose:** Uncompromising Python code formatter  
**Configuration:**
```yaml
tool:
  name: black
  type: formatter
  languages: [python]
  config_file: pyproject.toml
  command: black
  args:
    - "."
  integration:
    - vscode
    - pycharm
    - pre_commit
```

### gofmt (Go)
**Purpose:** Go code formatter  
**Configuration:**
```yaml
tool:
  name: gofmt
  type: formatter
  languages: [go]
  command: gofmt
  args:
    - "-w"
    - "."
  integration:
    - vscode
    - goland
    - pre_commit
```

## Static Analysis

### SonarQube
**Purpose:** Continuous code quality and security analysis  
**Configuration:**
```yaml
tool:
  name: sonarqube
  type: static_analysis
  languages: [java, javascript, python, csharp, php, ruby, kotlin, go]
  config_file: sonar-project.properties
  server_url: https://sonarqube.example.com
  features:
    - code_smells
    - bugs
    - security_vulnerabilities
    - code_coverage
    - duplication
  integration:
    - ci_cd
    - github
    - gitlab
```

### CodeQL
**Purpose:** Security-focused code analysis  
**Configuration:**
```yaml
tool:
  name: codeql
  type: security_analysis
  languages: [java, javascript, python, cpp, csharp, go, ruby]
  queries:
    - security-and-quality
    - security-extended
  integration:
    - github_actions
    - azure_devops
```

### PMD
**Purpose:** Source code analyzer (Java, JavaScript, etc.)  
**Configuration:**
```yaml
tool:
  name: pmd
  type: static_analysis
  languages: [java, javascript, xml, xsl]
  rulesets:
    - category/java/bestpractices.xml
    - category/java/errorprone.xml
    - category/java/security.xml
  integration:
    - maven
    - gradle
    - ci_cd
```

## Complexity Analysis

### Radon (Python)
**Purpose:** Python code complexity analyzer  
**Configuration:**
```yaml
tool:
  name: radon
  type: complexity_analyzer
  languages: [python]
  metrics:
    - cyclomatic_complexity
    - maintainability_index
    - raw_metrics
  thresholds:
    cc: 10
    mi: 20
```

### ESComplex (JavaScript)
**Purpose:** JavaScript complexity analyzer  
**Configuration:**
```yaml
tool:
  name: escomplex
  type: complexity_analyzer
  languages: [javascript]
  metrics:
    - cyclomatic_complexity
    - halstead_metrics
    - maintainability_index
```

## Integration Examples

### Pre-commit Hook
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v8.56.0
    hooks:
      - id: eslint
        args: [--fix]
  
  - repo: https://github.com/psf/black
    rev: 23.12.1
    hooks:
      - id: black
  
  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v3.1.0
    hooks:
      - id: prettier
```

### CI/CD Pipeline (GitHub Actions)
```yaml
name: Code Quality
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run ESLint
        run: npm run lint
      - name: Run Prettier
        run: npm run format:check
      - name: SonarQube Scan
        uses: sonarsource/sonarqube-scan-action@master
```

## Best Practices

1. **Run locally first** - Use pre-commit hooks to catch issues early
2. **Automate in CI** - Run all checks in CI/CD pipeline
3. **Fix automatically** - Use auto-fix features when available
4. **Set thresholds** - Define quality gates in CI
5. **Educate team** - Help team understand and fix issues
6. **Incremental adoption** - Start with critical rules, expand gradually
7. **Consistent config** - Share configuration across team
8. **Regular updates** - Keep tools and rules up to date
