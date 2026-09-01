---
name: retro
description: Mine recent sessions for recurring friction — repeated user corrections, repeated failures, skills or instructions that misfired, permission churn — and convert each recurring pattern into the smallest durable fix (a CLAUDE.md line, a skill edit, a memory update, a hook via update-config). Run it periodically ("run a retro") or after a session that went sideways. It maintains the memory system as it goes: updating stale entries, deleting wrong ones, consolidating duplicates.
---

# retro — turn recurring friction into durable fixes

A feedback loop for the working setup itself: find what keeps going wrong (or keeps needing to be
said), fix it at the source, and keep the memory system honest. One pass, smallest-possible fixes,
subtract before adding.

## Gather evidence
Scan whatever is available, delegating bulk reading to subagents:
- The current conversation: corrections the user made, things they had to say twice, work redone.
- Recent session transcripts for this project (`~/.claude/projects/<project-dir>/`), if present —
  a subagent per batch, reporting only recurring-friction candidates, not summaries.
- The memory directory: entries that contradict what you now know, duplicates, stale references.
- Signals worth counting: repeated permission prompts for the same safe command, a skill invoked
  and then manually overridden, the same lint/build gotcha hit in multiple sessions.
- Delegation health: Codex packet outcomes (shipped clean / N review round-trips / taken over) —
  the cost-per-completed-task trend, and whether the same steering countermeasure keeps being
  needed (if so, promote it into the codex-implement skill's steering section).

## Qualify — recurrence, not annoyance
A pattern earns a fix when it has happened at least twice, or once with clear generality. A
one-off stays a one-off; log nothing, change nothing. Do not invent problems to justify the run —
"no recurring friction found" is a valid and complete outcome.

## Fix at the right layer, smallest first
For each qualified pattern, pick ONE target:
- **Behavior you should change everywhere** → a line in `~/.claude/CLAUDE.md` — and prefer
  *removing or rewording* an existing line over adding a new one; instructions accrete, judgment
  doesn't need a manual.
- **A skill that misfired or under-specified** → edit that SKILL.md (trigger description or body).
- **A fact or preference worth recalling** → memory file, following the existing format; update or
  delete existing entries rather than duplicating.
- **An automated behavior or permission** → the update-config skill (hooks, settings, allowlists).
- **A recurring defect pattern in a project's code** → that project's issue tracker or CLAUDE.md,
  not the global setup.
New skills or agents require the strongest justification: the pattern must be recurring, and no
existing skill, agent, or one-line instruction can absorb it.

## Report
End with: each recurring pattern found (with its evidence), the fix applied and where, what was
deliberately left unchanged and why, and any memory entries updated or deleted. If the honest
finding is "nothing recurred," say exactly that.
