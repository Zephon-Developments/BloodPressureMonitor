# Tracy's Implementation Plan: Resolving Agent Definition Problems

## Restated Objectives/Constraints/Context
- **Objectives**: Update all agent definitions in `.github/agents` to fully comply with VS Code's custom agent format, ensuring valid frontmatter, tools, models, and handoffs for functional workflow.
- **Constraints**: Maintain existing agent roles (Steve coordinator, Tracy planner, Clive reviewer, Claudette general implementer, Georgina API specialist). Use only valid VS Code tools and supported models. Reference CODING_STANDARDS.md for consistency (e.g., clear documentation).
- **Context**: Current agents have incomplete frontmatter (missing `name`, `argument-hint`), invalid models, non-standard tools, and potentially incorrect handoffs. This prevents proper loading in VS Code.

## Architecture/Data Flow
- **Affected Files**: All 5 `.agent.md` files in `.github/agents`.
- **Data Flow**: Each agent file updated with correct YAML frontmatter; body remains for detailed instructions.
- **Sequencing**:
  1. Update Steve.agent.md (conductor).
  2. Update Tracy.agent.md (planner).
  3. Update Clive.agent.md (reviewer).
  4. Update Claudette.agent.md (implementer).
  5. Update Georgina.agent.md (API specialist).
- **Test Strategy**: After updates, validate by attempting to load agents in VS Code (check for parsing errors); run a sample workflow to ensure handoffs work.

## Decision Points and Assumptions
- **Models**: Assume supported models are claude-sonnet-4 (for coding), o1 (for planning), gpt-4o (for review). Confirm if others are available.
- **Tools**: Use standard VS Code tools like `readFile`, `editFile`, `runTerminalCommand`, `grepSearch`, etc. Map current custom tools to these.
- **Handoffs**: Ensure `send` field is correct (likely `true` for active handoffs).
- **Assumptions**: VS Code custom agents support the specified fields; no changes to agent responsibilities.

## Risks/Dependencies/Open Questions
- **Risks**: Incorrect tool names could break functionality; invalid models may cause load failures.
- **Dependencies**: Access to VS Code documentation for exact tool names and model support.
- **Open Questions**: What are the exact valid model names? Is `argument-hint` required? Confirm handoff structure.

## References to CODING_STANDARDS.md
- Section 3.1: Document all public aspects clearly (apply to agent descriptions).
- General: Maintain consistency and clarity in configurations.

## Plan Execution
- **Step 1**: Update frontmatter for each agent with `name`, `description`, `argument-hint`, valid `model`, mapped `tools`, corrected `handoffs`.
- **Step 2**: Validate updates by checking file syntax and VS Code compatibility.
- **Step 3**: Test workflow handoffs in a sample scenario.

This plan is concise and actionable for immediate execution by Claudette.