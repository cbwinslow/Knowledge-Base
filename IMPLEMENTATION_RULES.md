# ROBUST RULES FOR IMPLEMENTATION

## CORE OPERATING RULES

### 1. SCOPE CONTROL
- **ONLY work on tasks explicitly approved in this plan**
- **NO new features** unless specifically requested
- **NO major deletions** without explicit approval
- **STAY within defined boundaries** of pagination limits removal

### 2. CHANGE MANAGEMENT
- **READ files completely before editing**
- **MAKE backups** of any file before modifying
- **ONE change at a time** - test before proceeding
- **DOCUMENT every change** with clear reasoning

### 3. ERROR PREVENTION
- **STOP immediately** if uncertain about any change
- **ASK for clarification** before making assumptions
- **VERIFY API endpoints exist** before implementing
- **CHECK existing functionality** before modifying

### 4. TASK TRACKING
- **UPDATE todo list** for every completed task
- **MARK status changes** immediately
- **REFER to todo list** before starting new work
- **NO task switching** without completing current task

### 5. VALIDATION REQUIREMENTS
- **DRY-RUN first** before any execution
- **CHECK syntax** before running scripts
- **VERIFY parameters** before calling functions
- **CONFIRM database schemas** match API responses

### 6. COMMUNICATION PROTOCOLS
- **EXPLAIN changes** before making them
- **SHOW code differences** for approval
- **REPORT progress** at each milestone
- **ASK for help** when stuck or confused

## SPECIFIC TASK BOUNDARIES

### APPROVED TASKS:
1. ✅ Remove artificial pagination limits (`max_pages=10` → `999999`)
2. ✅ Implement smart pagination (auto-detect completion)
3. ✅ Ensure logging/monitoring performance
4. ✅ Verify GPU enhancement capabilities
5. ✅ Optimize duplicate prevention/removal
6. ✅ Validate optimal data types for OpenStates model

### FORBIDDEN ACTIONS:
- ❌ Creating new ingestion scripts (unless approved)
- ❌ Modifying database schemas (unless approved)
- ❌ Changing core architecture (unless approved)
- ❌ Bulk changes without testing
- ❌ Deleting existing functionality

## DECISION TREE FOR UNCERTAINTY

```
Is this change in the approved task list?
├─ NO → STOP and ASK for approval
└─ YES
   ├─ Am I 100% certain how to implement?
   │  ├─ NO → STOP and ASK for clarification
   │  └─ YES
   │     ├─ Have I read the entire file?
   │     │  ├─ NO → READ file completely first
   │     │  └─ YES
   │     │     ├─ Have I made a backup?
   │     │     │  ├─ NO → BACKUP file first
   │     │     │  └─ YES → PROCEED with change
   │     │           └─ UPDATE todo list
   └─ Will this affect existing functionality?
      ├─ YES → TEST thoroughly before proceeding
      └─ NO → PROCEED with caution
```

## PROGRESS CHECKPOINTS

### Before Each Change:
- [ ] Is this in the approved plan?
- [ ] Have I read the entire file?
- [ ] Do I understand the current implementation?
- [ ] Do I know exactly what to change?

### After Each Change:
- [ ] Did the change work as expected?
- [ ] Did I break anything?
- [ ] Should I update the todo list?
- [ ] Do I need to test this change?

## EMERGENCY PROTOCOLS

### If I Make a Mistake:
1. **STOP immediately**
2. **RESTORE from backup**
3. **ANALYZE what went wrong**
4. **REPORT** issue
5. **WAIT for approval before retrying**

### If I Get Confused:
1. **STOP all work**
2. **REVIEW** rules
3. **CHECK** todo list
4. **ASK** for clarification
5. **WAIT** for response

## IMPLEMENTATION FOCUS AREWS

### Current Priority: Pagination Limits Removal
- Focus: max_pages parameter changes
- Scope: Congress, OpenStates, Unified scripts
- Validation: Smart pagination implementation

### Secondary Focus Areas (Post-Pagination):
1. Logging/Monitoring Performance
2. GPU Enhancement Verification
3. Duplicate Prevention Optimization
4. OpenStates Data Type Validation

## RULES REFERENCE

**When in doubt, refer to these rules before proceeding.**
**If rules don't cover the situation, STOP and ASK.**
**Never assume approval for changes outside scope.**

---
*Created: 2025-01-14*
*Purpose: Keep implementation focused and on-track*
*Status: Active*