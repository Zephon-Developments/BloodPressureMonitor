# Clive Review – Agent Definition Remediation Plan

## Summary
- **Plan reviewed**: `tracy_agent_fix_plan.md`
- **Objective**: bring all `.github/agents/*.agent.md` files into compliance with VS Code custom agent format (frontmatter, tools, models, handoffs).

## Findings
1. **Coverage** – Plan enumerates every affected file and includes discovery, per-file fixes, body review, and validation. No gaps found.
2. **Standards alignment** – References `Documentation/Reference/CODING_STANDARDS.md` expectations for clarity/consistency.
3. **Model/tool mapping** – Proposed assignments are appropriate for each role. Confirmed availability in this workspace (`gpt-4o`, `claude-sonnet-4`, `o1`).
4. **Risk handling** – Identifies invalid tool/model risks and mitigation steps (doc cross-check, documentation notes).
5. **Open questions resolved** – Tool ids accepted list: `readFile`, `editFile`, `createFile`, `listDir`, `runTerminalCommand`, `grepSearch`, `semanticSearch`, `fetchWebpage`, `githubRepo`, `runTests`, `getErrors`, `getChangedFiles`. Steve should keep core orchestration set (read/search/edit minimal) without GitHub wildcards.

## Tests / Evidence
- Documentation/plan review only; no automated tests applicable at this stage.

## Verdict
- **Approved**. Plan is ready for implementation.

## Handoff – Claudette Implementation Instructions
- **Scope**: Apply plan sequencing across all `.github/agents/*.agent.md` files.
- **Tasks**:
  1. Update frontmatter per plan (add `name`, `argument-hint`, valid `model`, curated `tools`, normalized `handoffs`).
  2. Ensure body text references CODING_STANDARDS appropriately and stays concise.
  3. Validate syntax and run a smoke test by loading agents in VS Code.
- **Resources**: `tracy_agent_fix_plan.md`, confirmed model/tool lists above.
- **Deliverables back to Clive**: summary markdown with files changed, diffs, tests (YAML validation / agent load), and any deviations or follow-up questions.
