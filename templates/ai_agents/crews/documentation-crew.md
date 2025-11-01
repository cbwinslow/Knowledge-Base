# CrewAI Research & Documentation Crew Configuration

## Overview
This CrewAI configuration defines a crew of AI agents specialized in researching, documenting, and organizing knowledge base content.

## Agents

### 1. Research Agent
**Role**: Knowledge Researcher  
**Goal**: Find and collect high-quality documentation from various sources  
**Backstory**: Expert at finding technical documentation, tutorials, and examples across the web. Specializes in evaluating content quality and relevance.

**Tools**:
- Web search
- Documentation scraper
- GitHub API
- Context7 MCP server
- Link validator

### 2. Documentation Agent
**Role**: Technical Writer  
**Goal**: Transform raw content into well-structured, comprehensive documentation  
**Backstory**: Professional technical writer with expertise in creating clear, concise, and accurate documentation. Specializes in multiple programming languages and frameworks.

**Tools**:
- Markdown generator
- Code formatter
- Example validator
- Diagram generator

### 3. Organization Agent
**Role**: Knowledge Organizer  
**Goal**: Categorize and structure content in the knowledge base  
**Backstory**: Information architect specializing in taxonomy and knowledge organization. Expert at creating intuitive hierarchies and relationships.

**Tools**:
- File system operations
- Metadata tagger
- Category matcher
- Index builder

### 4. Quality Agent
**Role**: Quality Assurance Specialist  
**Goal**: Verify accuracy, completeness, and consistency of documentation  
**Backstory**: Experienced code reviewer and documentation auditor. Ensures all content meets quality standards and best practices.

**Tools**:
- Link checker
- Code validator
- Spell checker
- Consistency checker
- Duplicate detector

## Tasks

### Task 1: Content Discovery
**Description**: Search for and identify high-quality documentation sources  
**Agent**: Research Agent  
**Expected Output**: List of URLs with quality scores and relevance ratings

### Task 2: Content Extraction
**Description**: Download and extract content from identified sources  
**Agent**: Research Agent  
**Expected Output**: Raw content files with metadata

### Task 3: Content Processing
**Description**: Transform raw content into structured documentation  
**Agent**: Documentation Agent  
**Expected Output**: Well-formatted markdown files with examples

### Task 4: Content Organization
**Description**: Categorize and place content in appropriate directories  
**Agent**: Organization Agent  
**Expected Output**: Organized file structure with proper categorization

### Task 5: Quality Assurance
**Description**: Review and validate all processed content  
**Agent**: Quality Agent  
**Expected Output**: Quality report with any issues flagged

## Configuration

```python
from crewai import Agent, Task, Crew, Process

# Define Agents
research_agent = Agent(
    role="Knowledge Researcher",
    goal="Find and collect high-quality technical documentation",
    backstory="Expert at finding technical documentation, tutorials, and examples. "
              "Specializes in evaluating content quality and relevance.",
    verbose=True,
    allow_delegation=False,
    tools=[web_search, doc_scraper, github_api, context7_tool]
)

documentation_agent = Agent(
    role="Technical Writer",
    goal="Transform raw content into well-structured documentation",
    backstory="Professional technical writer with expertise in creating clear, "
              "concise, and accurate documentation.",
    verbose=True,
    allow_delegation=False,
    tools=[markdown_generator, code_formatter, example_validator]
)

organization_agent = Agent(
    role="Knowledge Organizer",
    goal="Categorize and structure content effectively",
    backstory="Information architect specializing in taxonomy and knowledge organization.",
    verbose=True,
    allow_delegation=False,
    tools=[file_ops, metadata_tagger, category_matcher, index_builder]
)

quality_agent = Agent(
    role="Quality Assurance Specialist",
    goal="Verify accuracy, completeness, and consistency",
    backstory="Experienced code reviewer and documentation auditor.",
    verbose=True,
    allow_delegation=False,
    tools=[link_checker, code_validator, spell_checker, consistency_checker]
)

# Define Tasks
task_discover = Task(
    description="Search for high-quality documentation about {topic}. "
                "Evaluate sources based on authority, completeness, and recency. "
                "Return top 20 sources with quality scores.",
    agent=research_agent,
    expected_output="List of 20 URLs with quality scores and descriptions"
)

task_extract = Task(
    description="Download content from identified sources. "
                "Extract main documentation, code examples, and relevant metadata. "
                "Handle different content formats (HTML, Markdown, PDF).",
    agent=research_agent,
    expected_output="Raw content files with metadata in staging directory"
)

task_process = Task(
    description="Transform raw content into structured documentation. "
                "Format code examples, add syntax highlighting, create clear sections. "
                "Ensure all links are relative and working.",
    agent=documentation_agent,
    expected_output="Well-formatted markdown files with processed content"
)

task_organize = Task(
    description="Categorize content based on topic, difficulty, and type. "
                "Place files in appropriate directory structure. "
                "Generate metadata tags and update indices.",
    agent=organization_agent,
    expected_output="Organized file structure with proper categorization"
)

task_qa = Task(
    description="Review all processed content for quality. "
                "Check for broken links, code errors, spelling mistakes. "
                "Verify consistency in formatting and style. "
                "Generate quality report.",
    agent=quality_agent,
    expected_output="Quality report with pass/fail status and any issues"
)

# Create Crew
documentation_crew = Crew(
    agents=[research_agent, documentation_agent, organization_agent, quality_agent],
    tasks=[task_discover, task_extract, task_process, task_organize, task_qa],
    process=Process.sequential,
    verbose=2
)

# Run Crew
result = documentation_crew.kickoff(inputs={"topic": "Docker best practices"})
```

## Usage

### Basic Usage
```python
from crews.documentation_crew import documentation_crew

# Research and document a topic
result = documentation_crew.kickoff(inputs={
    "topic": "Kubernetes deployment strategies"
})

print(result)
```

### Batch Processing
```python
topics = [
    "Docker Compose best practices",
    "FastAPI async patterns",
    "Next.js server components",
    "Terraform AWS modules",
    "PostgreSQL optimization"
]

for topic in topics:
    result = documentation_crew.kickoff(inputs={"topic": topic})
    print(f"Completed: {topic}")
```

### Custom Configuration
```python
# Adjust agent parameters
research_agent.max_iter = 10
research_agent.temperature = 0.7

# Run with custom inputs
result = documentation_crew.kickoff(inputs={
    "topic": "Vector databases",
    "depth": "advanced",
    "include_examples": True,
    "target_audience": "experienced developers"
})
```

## Output Structure

```
documentation/
└── [category]/
    └── [topic]/
        ├── README.md           # Overview
        ├── basics.md           # Basic concepts
        ├── advanced.md         # Advanced topics
        ├── examples/           # Code examples
        │   ├── example1.py
        │   └── example2.py
        └── metadata.json       # Metadata and tags
```

## Quality Metrics

The Quality Agent checks:
- **Completeness**: All sections present
- **Accuracy**: Code examples work
- **Consistency**: Formatting follows standards
- **Links**: All links are valid
- **Readability**: Clear and concise writing
- **Examples**: Working code with explanations

## Monitoring

Track crew performance:
```python
from crews.documentation_crew import documentation_crew

# Enable monitoring
crew.monitor = True

# Run and get metrics
result = documentation_crew.kickoff(inputs={"topic": "Redis caching"})

print(f"Tasks completed: {result.tasks_completed}")
print(f"Total time: {result.total_time}s")
print(f"Quality score: {result.quality_score}/100")
```

## Troubleshooting

### Common Issues

**Issue**: Content extraction fails
- **Solution**: Check source URL accessibility and format support

**Issue**: Poor quality score
- **Solution**: Review and manually improve content, then re-run QA

**Issue**: Slow processing
- **Solution**: Reduce batch size or increase agent timeouts

**Issue**: Categorization errors
- **Solution**: Review and update category matching rules

## Customization

### Adding Custom Tools
```python
from crewai_tools import tool

@tool
def custom_validator(code: str) -> bool:
    """Validate code using custom rules"""
    # Custom validation logic
    return True

# Add to agent
research_agent.tools.append(custom_validator)
```

### Modifying Tasks
```python
# Add preprocessing task
task_preprocess = Task(
    description="Preprocess content before extraction",
    agent=research_agent,
    expected_output="Preprocessed content list"
)

# Insert into crew
documentation_crew.tasks.insert(1, task_preprocess)
```

## Best Practices

1. **Start Small**: Test with one topic before batch processing
2. **Review Output**: Manually review first few results
3. **Tune Parameters**: Adjust agent settings based on results
4. **Monitor Quality**: Check quality scores and address issues
5. **Iterate**: Continuously improve based on feedback

## Future Enhancements

- **Multilingual Support**: Add translation agent
- **Interactive Mode**: Allow human-in-the-loop review
- **Auto-Update**: Scheduled re-processing of outdated content
- **Learning**: Crew learns from manual corrections
- **Collaboration**: Multiple crews working on different topics

---

**Version**: 1.0  
**Last Updated**: 2025-11-01  
**Status**: Production Ready
