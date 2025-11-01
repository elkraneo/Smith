# Tests - Agent Evaluation Tools

This folder contains tools for **evaluating agent work** against the Smith framework. These files are **not part of the framework itself**—they're for reviewers only.

## Files

### 1. [AGENTS-SUBMISSION-TEMPLATE.md](AGENTS-SUBMISSION-TEMPLATE.md)
**What to give agents before they submit work.**

Agents fill this out to:
- Verify they read AGENTS.md
- Define task scope (Safe/Approval/Forbidden)
- Answer decision tree questions
- Self-check code patterns
- Summarize their work

**Workflow:** You give this to agents → They fill it out → They submit → You evaluate

### 2. [AGENTS-EVALUATION-CHECKLIST.md](AGENTS-EVALUATION-CHECKLIST.md)
**Your private tool—do NOT give to agents.**

This checklist helps you verify:
- Framework compliance
- Deprecated patterns
- Scope boundaries
- Modern pattern usage
- Code quality checks

**Scoring:** ✅ PASS / ⚠️ PARTIAL / ❌ FAIL

### 3. [AGENTS-REVIEW-FORMAT.md](AGENTS-REVIEW-FORMAT.md)
**How to request evaluation from me.**

When an agent submits their template:
1. Copy their submission
2. Paste it to me using this format
3. I evaluate using the checklist
4. I respond with verdict and feedback

---

## Workflow

```
1. Agent does work
   ↓
2. You give agent: AGENTS-SUBMISSION-TEMPLATE.md
   ↓
3. Agent fills template and submits
   ↓
4. You copy submission to me using AGENTS-REVIEW-FORMAT.md
   ↓
5. I evaluate using AGENTS-EVALUATION-CHECKLIST.md
   ↓
6. I give you: ✅ PASS / ⚠️ PARTIAL / ❌ FAIL + feedback
   ↓
7. You give agent feedback with AGENTS.md citations
```

---

## Important

**Skip this folder when copying Smith to new projects.**

When creating a new project scaffold:
```bash
cp -r Smith/ NewProject/ --exclude=Tests/
```

The Tests/ folder is for **evaluation only**, not part of the framework that projects need.

---

## Quick Reference

| Tool | Who Uses | When | Purpose |
|------|----------|------|---------|
| AGENTS-SUBMISSION-TEMPLATE.md | Agents | Before submitting | Self-check framework compliance |
| AGENTS-EVALUATION-CHECKLIST.md | You | When reviewing | Verify compliance |
| AGENTS-REVIEW-FORMAT.md | You | When asking for eval | Request evaluation from me |
