# Agent Definition Remediation Plan (Tracy → Clive)

## Restated Objectives
- Fix all agent definitions in `.github/agents` to comply with VS Code custom agent format so they load and function correctly.
- Preserve existing roles and workflow (Steve coordinator → Tracy planner → Clive reviewer → Claudette/Georgina implementers).

## Scope
- Files: `.github/agents/Steve.agent.md`, `Tracy.agent.md`, `Clive.agent.md`, `Claudette.agent.md`, `Georgina.agent.md` (verify if a `coder.agent.md` exists elsewhere; none listed currently).
- Frontmatter compliance: `name`, `description`, `argument-hint`, `model`, `tools`, `handoffs`.
- Valid models: prefer `gpt-4o` (review/coordination), `claude-sonnet-4` (implementation), `o1` (planning). Adjust if workspace constraints differ.
- Tools: use VS Code-recognized tool ids (e.g., `readFile`, `editFile`, `createFile`, `runTerminalCommand`, `grepSearch`, `semanticSearch`, `listDir`, `getErrors`, `getChangedFiles`, `runTests`, `fetchWebpage`). Remove vendor-specific or nonstandard entries.
- Handoffs: ensure `label`, `agent`, `prompt`, and `send: true` are present where appropriate and reflect the intended workflow.

## Constraints & References
- Maintain agent responsibilities and workflow sequencing; no scope creep on roles.
- Follow clarity/documentation expectations per `Documentation/Reference/CODING_STANDARDS.md` (assumed path; verify existence).
- Keep instructions concise and actionable.

## Success Metrics
- All agent files parse without errors in VS Code custom agents.
- Frontmatter includes required keys with valid values.
- Tools lists contain only supported tool ids; no wildcards or deprecated entries.
- Models are valid and appropriate to roles.
- Handoffs reflect the intended workflow and include `send: true` where needed.

## Plan / Sequencing
1) **Discovery/Validation**
   - List `.github/agents` to confirm current files; check if `coder.agent.md` exists elsewhere (search workspace if needed).
   - Verify presence of `Documentation/Reference/CODING_STANDARDS.md`; if missing, note assumption.
2) **Per-file Frontmatter Fixes**
   - Add `name` and `argument-hint` where missing.
   - Replace nonstandard models with valid ones (see model mapping below).
   - Replace tool lists with standard tool ids (see tool mapping below).
   - Normalize handoffs to `label`, `agent`, `prompt`, `send: true` and ensure workflow correctness.
3) **Body Review**
   - Ensure body text matches role and references CODING_STANDARDS where relevant; keep concise and consistent.
4) **Validation**
   - Syntax check (basic YAML/frontmatter correctness).
   - Smoke test: load agents in VS Code (manual) and confirm no parsing errors.

## Model Mapping (proposed)
- Steve (coordination): `gpt-4o`
- Tracy (planning): `o1`
- Clive (review): `gpt-4o`
- Claudette (implementation): `claude-sonnet-4`
- Georgina (API/implementation): `claude-sonnet-4`

## Tool Mapping (use subset per role)
- Common: `readFile`, `grepSearch`, `semanticSearch`, `listDir`
- Editing/creation: `editFile`, `createFile`, `runTerminalCommand`
- QA: `runTests`, `getErrors`, `getChangedFiles`
- Web/reference: `fetchWebpage`, `githubRepo` (if available)
- Planner (Tracy): typically read/search only; omit editFile unless required
- Reviewer (Clive): read/search, `runTests`, `getErrors`, `getChangedFiles`
- Implementers (Claudette/Georgina): full edit/create/test toolset
- Steve: orchestration set (read/search/edit minimal) to patch context if needed

## Risks & Mitigations
- **Invalid tool ids**: Cross-check against VS Code custom agent docs; avoid wildcards like `github/*` or nonstandard vendor ids.
- **Invalid models**: If listed models unsupported, adjust to available set; document choice.
- **Missing CODING_STANDARDS**: If file absent, note in handoff and keep references generic.

## Open Questions for Clive
- Confirm available model set in this environment.
- Confirm exact VS Code tool id list supported here.
- Should Steve retain any GitHub-specific tools, or keep minimal core toolset?

## Handoff Package to Clive
- This plan file: `tracy_agent_fix_plan.md`
- Ask Clive to confirm model/tool availability and approve mappings before implementation.

## Next Steps (for Claudette after approval)
- Apply frontmatter/tool/model/handoff fixes per mapping above to all agent files.
- Validate syntax; run a minimal smoke test by loading agents in VS Code.
- Prepare a short implementation note for Clive with diffs and any deviations.
