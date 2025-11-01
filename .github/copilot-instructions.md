# GitHub Copilot Instructions for Knowledge Base Repository

## Project Context
This is a comprehensive knowledge base covering DevOps, AI/ML, Programming, Infrastructure, Web Technologies, Databases, Security, and more. The repository serves as a reference library with documentation, examples, templates, and boilerplates.

## Code Style Preferences

### General
- **Clarity over cleverness**: Write readable, self-documenting code
- **Comments**: Add explanatory comments for complex logic
- **Naming**: Use descriptive names (prefer `user_authentication_service` over `uas`)
- **Organization**: Keep files focused and modular

### Python
- Follow PEP 8 style guide
- Use type hints for function parameters and return values
- Prefer f-strings for string formatting
- Use list/dict comprehensions when they improve readability
- Add docstrings to all functions and classes (Google style)

```python
def process_documentation(source_url: str, category: str) -> dict[str, any]:
    """
    Process documentation from a source URL and categorize it.
    
    Args:
        source_url: The URL to fetch documentation from
        category: The category to organize the documentation under
        
    Returns:
        A dictionary containing processed documentation metadata
        
    Raises:
        ValueError: If source_url is invalid
        HTTPError: If the request fails
    """
    pass
```

### TypeScript/JavaScript
- Use TypeScript for all new code
- Enable strict mode in tsconfig.json
- Prefer const over let, avoid var
- Use async/await over promise chains
- Add JSDoc comments for public APIs

```typescript
/**
 * Fetches and processes documentation from a given source
 * @param sourceUrl - The URL to fetch from
 * @param options - Configuration options
 * @returns Processed documentation metadata
 * @throws {Error} If the URL is invalid or request fails
 */
async function processDocumentation(
  sourceUrl: string,
  options: ProcessOptions
): Promise<DocumentationResult> {
  // Implementation
}
```

### Go
- Follow effective Go guidelines
- Use gofmt for formatting
- Add package-level documentation
- Handle all errors explicitly
- Use context for cancellation

### Rust
- Follow Rust API guidelines
- Use rustfmt for formatting
- Prefer Result<T, E> over panics
- Document all public items
- Use clippy for linting

## Framework-Specific Patterns

### Next.js
- Use App Router (app/) not Pages Router
- Prefer Server Components by default
- Use "use client" only when necessary
- Implement proper loading states
- Use next/image for images
- Implement proper error boundaries

### React
- Use functional components with hooks
- Prefer composition over inheritance
- Keep components small and focused
- Use proper prop types or TypeScript interfaces
- Implement proper key props in lists

### FastAPI
- Use Pydantic models for request/response validation
- Add proper OpenAPI documentation
- Implement dependency injection for shared logic
- Use async def for I/O-bound operations
- Add proper error handling and HTTP status codes

## Security Requirements

### General
- Never commit secrets, API keys, or passwords
- Use environment variables for sensitive data
- Validate all user inputs
- Sanitize outputs to prevent XSS
- Use parameterized queries to prevent SQL injection

### API Security
- Implement authentication and authorization
- Use HTTPS only
- Implement rate limiting
- Add CORS properly
- Validate content types

### Docker
- Use official base images
- Run containers as non-root users
- Scan images for vulnerabilities
- Keep dependencies updated
- Use multi-stage builds to reduce image size

## Testing Standards

### Unit Tests
- Test one thing per test
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)
- Mock external dependencies
- Aim for high coverage on critical paths

```python
def test_documentation_processor_handles_invalid_url():
    # Arrange
    processor = DocumentationProcessor()
    invalid_url = "not-a-url"
    
    # Act & Assert
    with pytest.raises(ValueError, match="Invalid URL"):
        processor.process(invalid_url)
```

### Integration Tests
- Test real interactions between components
- Use test databases, not production
- Clean up after tests
- Test happy paths and error cases

## Documentation Standards

### README Files
Every directory should have a README.md with:
- **Purpose**: What this directory contains
- **Structure**: How it's organized
- **Usage**: How to use the contents
- **Examples**: Quick examples where applicable
- **Related**: Links to related directories

### Code Examples
- Include complete, working examples
- Add comments explaining key concepts
- Show both basic and advanced usage
- Include error handling
- Mention prerequisites and dependencies

### API Documentation
- Document all public functions/methods
- Include parameter types and descriptions
- Document return values
- List possible exceptions/errors
- Provide usage examples

## File Organization

### Directory Structure
```
category/
├── subcategory/
│   ├── README.md           # Overview and navigation
│   ├── basics/             # Beginner content
│   ├── intermediate/       # Intermediate content
│   ├── advanced/           # Advanced content
│   └── examples/           # Working code examples
```

### Naming Conventions
- Use lowercase with underscores for files: `user_authentication.py`
- Use kebab-case for directories: `user-authentication/`
- Use PascalCase for classes: `UserAuthentication`
- Use camelCase for JavaScript/TypeScript: `userAuthentication`

## Common Patterns

### Error Handling
```python
# Python
try:
    result = process_data(data)
except ValueError as e:
    logger.error(f"Invalid data: {e}")
    raise
except Exception as e:
    logger.exception("Unexpected error")
    raise ProcessingError("Failed to process data") from e
```

```typescript
// TypeScript
try {
  const result = await processData(data);
  return result;
} catch (error) {
  if (error instanceof ValidationError) {
    logger.error('Invalid data:', error);
    throw error;
  }
  logger.error('Unexpected error:', error);
  throw new ProcessingError('Failed to process data', { cause: error });
}
```

### Configuration
- Use `.env` files for local development
- Use `.env.example` as template (no secrets)
- Use proper config management (pydantic-settings, dotenv)
- Validate configuration on startup

### Logging
```python
# Python
import logging

logger = logging.getLogger(__name__)

logger.info("Processing started", extra={"source": source_url})
logger.warning("Slow response", extra={"duration_ms": duration})
logger.error("Failed to process", exc_info=True)
```

## Git Commit Messages

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Formatting changes
- **refactor**: Code restructuring
- **test**: Adding tests
- **chore**: Maintenance tasks

### Examples
```
feat(examples): add Python async/await examples

Add comprehensive examples demonstrating async/await patterns in Python
including concurrent requests, async generators, and error handling.

Closes #123
```

## Copilot-Specific Tips

### When Suggesting Code
- Provide context in comments before complex code
- Suggest multiple approaches when appropriate
- Include error handling in suggestions
- Add inline comments explaining non-obvious logic
- Suggest relevant imports

### When Refactoring
- Preserve existing functionality
- Improve readability and maintainability
- Add tests if missing
- Update documentation
- Suggest performance improvements cautiously

### When Adding Features
- Follow existing patterns in the codebase
- Add appropriate tests
- Update relevant documentation
- Consider edge cases
- Implement proper error handling

## Templates Usage

When suggesting code from templates:
1. Adapt to the specific use case
2. Update placeholder values
3. Add necessary error handling
4. Include relevant comments
5. Suggest related templates

## Quality Checklist

Before suggesting code, ensure:
- [ ] Follows project style guidelines
- [ ] Includes proper error handling
- [ ] Has appropriate documentation
- [ ] Uses type hints/annotations
- [ ] No hardcoded secrets or credentials
- [ ] Imports are organized
- [ ] Variable names are descriptive
- [ ] Edge cases are handled
- [ ] Related files are updated

## Resources

- [Project README](../README.md)
- [Documentation Index](../documentation/INDEX.md)
- [Examples](../documentation/examples_scripts/)
- [Templates](../templates/)
- [Improvements Doc](../KNOWLEDGE_BASE_IMPROVEMENTS.md)

---

**Remember**: The goal is to create a high-quality, maintainable knowledge base that serves as a reliable reference for developers. Prioritize clarity, correctness, and completeness in all suggestions.
