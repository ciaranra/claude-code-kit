---
name: codex-scout
description: Offload read-only busywork to Codex (OpenAI's coding-agent CLI) — codebase reconnaissance, call-site and usage inventories, subsystem summaries, draft artifacts (docs, test skeletons, configs), and first-pass review of low-stakes diffs. Zero write risk (read-only sandbox); results come back as a saved report. Use it to conserve Claude/Fable capacity for planning, evaluation, and synthesis whenever the work is mechanical reading or drafting rather than judgment. Codex credits are the cheap resource; Fable attention is the scarce one.
---

# codex-scout — Codex reads and drafts, Fable thinks

Send Codex out read-only to gather, inventory, summarize, or draft. Nothing it produces is a
decision: interpretation, packet design, architecture, and verdicts stay with you. The economic
rule this skill exists for: **Codex credits are abundant, Fable attention is the scarce
resource** — any task that is mostly *reading many files* or *producing a first draft* should
cost Codex tokens, not yours.

**Preflight:** same as the sibling skills — `codex login status`; data boundary (repo content
goes to OpenAI; only on code the user is cleared to share).

## Good scout tasks
- **Packet-prep reconnaissance** — before writing a /codex-implement packet: "inventory every
  call site of X with file:line and the surrounding calling convention", "summarize how module Y
  handles errors/ownership/naming so a packet can demand style-match".
- **Usage and dependency maps** — which crates/modules consume an API you intend to change;
  what breaks if a signature moves.
- **Subsystem summaries** — a structured brief of an unfamiliar area, produced without spending
  your own context reading 30 files.
- **Draft artifacts** — first drafts of docs, README sections, test skeletons, CI configs,
  migration checklists. Drafts come back in the report; you edit and place them.
- **First-pass review of LOW-stakes diffs** — `codex review --base <ref>` (or `--uncommitted`)
  in a fresh session as the basic-review pass; you read the findings, not the diff. Scope flags
  cannot be combined with a custom prompt (codex-cli 0.145.0 errors); custom instructions go
  through `codex exec` instead. Load-bearing
  work still gets the full review pipeline (qa-verifier + adversarial arm + your own read).

## Not scout tasks
- Anything whose output you would act on without checking — a scout report feeds your judgment,
  it does not replace it.
- Packet design, architecture decisions, review verdicts, plan/vision upkeep.
- Investigation where the question is subtle enough that misreading the code changes the plan —
  read that yourself.

## Invocation
From the repo root (`-C <repo-root>`), read-only sandbox. Effort `medium` for anything requiring
real code comprehension, `low` for pure enumeration:
```
codex exec -C <repo-root> --sandbox read-only \
  -c model_reasoning_effort='"medium"' \
  -o <scratchpad>/scout-<topic>.md \
  "<self-contained prompt>" </dev/null > <scratchpad>/scout-<topic>.log 2>&1
```
**Do not pin a model here.** `~/.codex/config.toml` owns that choice; hardcoding a model ID in a
skill goes stale silently and then requests a model that may no longer exist. (This file pinned
`gpt-5.6-terra` long after the configured default had moved on — caught 2026-09-05.) Effort and
service tier are stable concepts and are worth pinning explicitly; model names are not.

**The cheap-model lever no longer exists — effort is the lever.** Earlier guidance here said to
route scouting to a smaller tier. As of GPT-6 Astra there is a single dense model with no mini or
nano variant, so the only cost controls are reasoning effort and service tier. Cost per task by
effort: low $0.63 / medium $1.16 / high $1.41 / xhigh $1.85 / max $2.57.

So for scouting: **`low` for pure enumeration, `medium` for anything needing real code
comprehension.** Do not reach past that here — if a scout task hinges on subtly reading code, that
is a signal it belongs to you (see "Not scout tasks"), not that it needs more effort. Reserve high
and above for `/codex-implement` and high-stakes review.

**`service_tier='"fast"'` doubles the cost.** Scout runs are backgrounded and you end the turn
anyway, so latency is free — omit it unless you are genuinely blocked on the report.
- `run_in_background: true`, then end the turn — completion notifies you; never poll.
- Codex has NO conversation context: the prompt must be self-contained (what to find, where to
  start, what the repo is, exact output format).
- **Demand structured output**: "cite file:line for every claim; output as a table/list, no
  narrative". An inventory you can't spot-check is an inventory you can't use.
- Read back ONLY the `-o` report file, never the log (stderr reasoning bloats context).

## Trust, but verify
Scout reports are unreviewed model output. Before load-bearing use, spot-check 2-3 cited
file:line claims yourself; if any is wrong, treat the whole report as a lead-generator, not a
source of record. Never paste a scout summary into a design doc or packet without that check.
