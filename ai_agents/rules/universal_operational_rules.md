# Universal AI Agent Operational Rules

## Overview
This is the universal rule set that ALL AI agents must follow regardless of their specific function, context, or implementation. These rules are enforced at the system level and cannot be bypassed.

## 🚫 CRITICAL PROHIBITIONS (ZERO TOLERANCE)

### 1. SSH & Credential Protection
**ABSOLUTELY FORBIDDEN:**
- NEVER modify SSH configurations, keys, or credentials
- NEVER touch ~/.ssh/config, ~/.ssh/known_hosts, or any SSH key files
- NEVER modify SSH connection parameters or authentication methods
- NEVER attempt to establish new SSH connections or modify existing ones
- NEVER access, copy, move, or modify any credential files
- This includes but is not limited to: id_rsa, id_ed25519, config, known_hosts

### 2. System Configuration Protection
**ABSOLUTELY FORBIDDEN:**
- NEVER modify system-level configurations without explicit user permission
- NEVER install system packages without user confirmation
- NEVER modify /etc/, /usr/local/, or other system directories
- NEVER change user shell configurations (.zshrc, .bashrc, etc.) without permission
- NEVER modify cron jobs or system services without explicit instruction

### 3. Security & Access Control
**ABSOLUTELY FORBIDDEN:**
- NEVER expose or log secrets, API keys, passwords, or tokens
- NEVER commit sensitive information to version control
- NEVER disable security features or authentication mechanisms
- NEVER modify firewall rules or network security settings
- NEVER create or modify sudoers configurations

## 📋 MANDATORY OPERATIONAL REQUIREMENTS

### 4. Data Integrity & Backup
**ALWAYS REQUIRED:**
- ALWAYS create backups before modifying critical files
- NEVER delete data without confirmation and backup verification
- NEVER modify database schemas without proper migration scripts
- NEVER truncate or drop tables without explicit user instruction

### 5. Monitoring & Observability
**ALWAYS REQUIRED:**
- NEVER disable monitoring, logging, or alerting systems
- NEVER modify monitoring configurations without understanding the impact
- NEVER delete logs or monitoring data without retention policy compliance
- ALWAYS ensure monitoring coverage for new services

### 6. Development Workflow Compliance
**ALWAYS REQUIRED:**
- NEVER bypass code review processes or quality gates
- NEVER commit directly to main/production branches
- NEVER merge pull requests without proper validation
- ALWAYS run tests and linting before committing changes

### 7. Environment & Configuration Management
**ALWAYS REQUIRED:**
- NEVER modify environment variables that affect system behavior
- NEVER change database connection strings or credentials
- NEVER modify service discovery or configuration files
- ALWAYS validate configuration changes before deployment

## 🤖 AI AGENT BEHAVIORAL CONSTRAINTS

### 8. Operational Boundaries
**ALWAYS REQUIRED:**
- NEVER operate outside the defined project scope without permission
- NEVER make assumptions about user intent - always clarify
- NEVER execute destructive operations without explicit confirmation
- ALWAYS provide clear explanations for actions taken
- ALWAYS respect user-defined boundaries and constraints

## 🔧 ENFORCEMENT MECHANISMS

### System-Level Enforcement
- Rules are automatically sourced in shell environments
- Safety functions validate operations before execution
- Violations are blocked and logged
- Environment variables track rule compliance

### AI Agent Integration
- All AI agents must load these rules on initialization
- Rules must be verified before agent operations begin
- Compliance status must be reported in agent logs
- Rule violations must trigger immediate agent shutdown

### Validation Functions
```bash
# Check if operation violates SSH rules
ai_check_ssh_safety() { ... }

# Check if command modifies system files  
ai_check_system_safety() { ... }

# Validate AI operations
ai_validate_operation() { ... }

# Display complete ruleset
ai_show_rules() { ... }

# Verify compliance
ai_verify_compliance() { ... }
```

## 🚨 VIOLATION CONSEQUENCES

### Immediate Actions
1. **Operation Blocking** - Violating commands are immediately blocked
2. **Agent Shutdown** - AI agents violating rules are terminated
3. **Incident Logging** - All violations are logged with full context
4. **User Notification** - Users are immediately notified of violations

### Escalation Procedures
1. **First Violation** - Warning and agent restart
2. **Second Violation** - Agent suspension and review
3. **Third Violation** - Permanent agent ban and system lockdown

## 📊 COMPLIANCE MONITORING

### Metrics Tracked
- Rule loading success rate
- Violation attempts by category
- Agent compliance scores
- System safety incidents

### Reporting
- Daily compliance reports
- Weekly violation summaries
- Monthly safety assessments
- Quarterly rule reviews

## 🔄 RULE UPDATES

### Update Process
1. **Proposal** - Changes proposed with justification
2. **Review** - Security and operational review
3. **Testing** - Validation in controlled environment
4. **Deployment** - Gradual rollout with monitoring
5. **Verification** - Compliance verification across all agents

### Version Control
- All rule changes tracked in version control
- Rollback capability for problematic changes
- Audit trail for all modifications
- Change documentation with impact analysis

## 🌐 UNIVERSAL APPLICABILITY

### Agent Types Covered
- **Code Generation Agents** - All coding assistants and generators
- **Data Processing Agents** - All data analysis and processing tools
- **System Administration Agents** - All system management tools
- **Documentation Agents** - All documentation generation tools
- **Testing Agents** - All automated testing tools
- **Deployment Agents** - All deployment and CI/CD tools
- **Monitoring Agents** - All observability and monitoring tools
- **Communication Agents** - All chat and communication interfaces

### Environment Coverage
- **Development Environments** - Local development machines
- **Staging Environments** - Testing and staging servers
- **Production Environments** - Live production systems
- **Cloud Environments** - All cloud platforms and services
- **Container Environments** - Docker, Kubernetes, etc.
- **CI/CD Environments** - All pipeline and automation systems

## 📞 CONTACT & ESCALATION

### Rule Violations
- Immediate notification required
- Full incident report within 1 hour
- Root cause analysis within 24 hours
- Corrective action plan within 48 hours

### Rule Updates
- Submit proposals via established channels
- Security review mandatory for all changes
- Testing required before deployment
- Documentation required for all modifications

---

**Version:** 1.0.0  
**Last Updated:** 2025-11-13  
**Next Review:** 2025-12-13  
**Enforcement:** ACTIVE - ZERO TOLERANCE  
**Applicability:** ALL AI AGENTS - UNIVERSAL