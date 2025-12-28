# Handoff to Tracy: Plan Resolution of Agent Definition Problems

## Context from Steve
- **Request Origin**: User identified multiple problems with agent definitions in `.github/agents`.
- **Current Agents**: Claudette.agent.md, Clive.agent.md, Georgina.agent.md, Steve.agent.md, Tracy.agent.md.
- **Identified Issues**:
  - Missing required frontmatter fields: `name` and `argument-hint` (VS Code custom agents require: name, description, argument-hint, model, tools, handoffs).
  - Invalid or non-standard model names (e.g., "GPT-5.1-Codex-Max", "Claude Sonnet 4.5", "Gemini 3 Pro (Preview)") - need to use valid models like claude-sonnet-4, o1, gpt-4o.
  - Tools listed in non-standard format; need to use actual VS Code tool names (e.g., readFile, editFile, runTerminalCommand, etc.).
  - Handoffs may have incorrect structure (e.g., "send: true" might not be standard).
  - Overall format may not comply with VS Code's custom agent specifications.

## Scope
- Update all five agent files to full VS Code custom agent format compliance.
- Ensure handoffs are correct and workflow remains functional.
- Reference Documentation/Reference/CODING_STANDARDS.md where applicable (though this is for agents, not code).

## Constraints
- Maintain the Tracy → Implementation → Clive workflow.
- Do not change agent roles or responsibilities.
- Use valid VS Code tools and models.
- Keep agents specialized as is (Steve coordinator, Tracy planner, Clive reviewer, Claudette general implementer, Georgina API specialist).

## Success Metrics
- All agents have proper YAML frontmatter with name, description, argument-hint, model, tools, handoffs.
- Tools are valid VS Code tool names.
- Models are supported (e.g., claude-sonnet-4, o1, gpt-4o).
- Handoffs enable smooth workflow transitions.
- Agents can be loaded and used in VS Code without errors.

## Next Steps
Tracy, please produce a solid plan outlining how to resolve these issues, including:
- Specific changes needed for each agent.
- Sequencing of updates.
- Risks, dependencies, and assumptions.
- Reference to any relevant standards.
- Decision points needing confirmation.

Once plan is ready, hand off to Clive for review.