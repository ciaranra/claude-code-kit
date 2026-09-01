---
name: deep-research
description: For a high-stakes or fast-moving question in ANY domain — a decision between options (approach, method, vendor, tool, material, design), a best-practice or standard, a factual "current state / consensus on X", a comparison, or a claim to verify — run an independent multi-source research panel and fuse the findings by merit, rather than trusting a single search or your own (cutoff-limited) training. Assemble researchers along diverse axes of independence — live web search (recency), a different model's web access (e.g. Codex — different index and training), and optionally a subagent aimed at one facet (a sub-question, a counter-position, primary vs. secondary sources, a cost/risk/safety/regulatory angle) — each grounding every claim in a cited source and blind to each other and to your hypotheses; then cross-check each finding against its source and synthesize: corroboration raises confidence, a solo finding is the sharp non-overlapping catch, a conflict (including vs. your own prior) is the thing to resolve. Scales from two arms up. Use when being wrong or STALE is expensive; for a quick fact, a single web search is plenty.
---

# deep-research — independent multi-source research panel, fused by merit

For a question where being wrong or **stale** is expensive — choosing between options, settling a
best-practice, "what's the current state of / consensus on X", verifying a load-bearing claim — in
**any** field (engineering, science, operations, purchasing, medicine/lab work, policy, finance,
history…), don't trust a single search or your own training (which has a cutoff). Run an **independent
panel of researchers** from **different vantage points** and **fuse their findings by merit**. You are
the orchestrator: you cross-check every claim against its cited source and synthesize one grounded answer.

## The principle: diverse axes of independence, fused by merit
One searcher has one set of blind spots — a stale index, one query framing, a training cutoff, a single
kind of source. A panel wins when its arms are independent along *different* axes, each covering what the
others can't:
- **Live web** — current results your training can't contain (recency; the field moved since your cutoff).
- **A different model's research** — a non-Claude researcher (e.g. Codex) has a different index and
  training, so it surfaces what a Claude-family pass systematically underweights.
- **A focused facet** (optional) — a subagent aimed at one dimension: a specific sub-question, the
  strongest *counter*-position, primary sources vs. secondary summaries, or a cost / risk / safety /
  legal / regulatory angle — goes deeper there than a broad pass.

**Your training data is a *prior*, not a source.** Treat it as a hypothesis to verify, and cite a live
source for every load-bearing claim.

## Assemble the panel — in parallel, and BLIND
Kick all arms off at once (one message, concurrent), each given only the **question + what to find** —
NOT your hypotheses, your leaning, or another arm's output. Anchoring collapses the independence that
makes the panel worth running.

**Exception — multiple Codex arms (learned 2026-07-14)**: do NOT run two `codex` CLI instances
concurrently under ChatGPT-login OAuth. They share `~/.codex/auth.json`, whose single-use refresh
token rotates on every refresh; concurrent instances race the redemption and losers wedge silently
(process alive, zero CPU, nothing written under `~/.codex` — openai/codex#10332). For TRUE concurrency use the
verified isolated-home recipe (tested 2026-07-14: simultaneous execs, both completed, no
cross-revocation): second identity lives at `~/.codex-arm2` (`mkdir` it first, then one-time
`CODEX_HOME=$HOME/.codex-arm2 codex login`); run arm 2 as
`CODEX_HOME=$HOME/.codex-arm2 codex --search exec ...`. Both homes bill to the same ChatGPT
subscription. Fallback when only one home exists: sequential (`cmd1; cmd2` inside ONE background
task) — blindness does not require simultaneity. Detection of the shared-home wedge:
`find ~/.codex -mmin -2` empty + zero CPU = wedged, not thinking.

The high-value default is **two arms**:
- **Web-search arm** — a fresh subagent (or your own searches) that gathers current sources; every claim
  carries a URL. Prompt it to find the *current best answer AND where the obvious/popular answer may be
  wrong or outdated*.
- **Cross-model arm** — run the same question through a different model/tool with web access (e.g. the
  `codex` CLI), framed the same adversarial way. **Mind the data boundary** (as in `codex-review`): only
  send context the user is cleared to share with that provider.

Scale up with a **facet arm** (a counter-position, primary sources, a cost/risk/safety/regulatory angle,
a specific sub-question, a time window) when the stakes justify it. The protocol is identical for N arms.

## Fuse by merit — the actual work
Collect every arm's findings, then **verify each claim against its cited source yourself** — the panel
proposes, you dispose. Sort each finding:
- **Corroborated** (≥2 arms, independent sources) → high confidence; act on it.
- **Solo** (one arm) → the non-overlapping coverage you ran the panel for; evaluate on merit, do NOT
  discount it for being solo — the sharpest catches are often single-arm.
- **Conflict** (arms disagree, OR an arm contradicts your training prior) → the most informative signal;
  resolve it against the sources and report which was right and why. A confident training prior overturned
  by a live source is exactly the stale-knowledge failure this skill exists to catch.

Then dedupe overlaps, refute the wrong claims (with the source that refutes them), and synthesize **one
answer + a confidence-tagged, source-cited findings list**. Close with a quick "what might ALL arms have
missed?" — a shared blind spot (every arm leaned on the same source, none consulted a primary source or a
dissenting view, no one checked a cost/legal/safety angle) is the panel's one real weakness.

## After
- For a decision, state the **recommendation + the 2–3 findings it rests on**, each with a source URL.
- Prefer verifying over adopting: a claim you couldn't source is a hypothesis, not a finding — say so.
- Distinguish source quality (primary/peer-reviewed/official vs. blog/forum/vendor) in what you report.
- For high-stakes work, keep the artifacts (each arm's raw findings + your fusion) with the project's
  design/research records.

## When NOT to use
A single quick fact, a well-known settled matter, or anything one web search resolves — a panel costs more
than it's worth. Reserve it for choices that are expensive to get wrong or that your training is likely
stale or thin on.

## Target
The user's request names the question — a decision, a comparison, a best-practice, a "state of X", a claim
to check. If it's unclear what to research or how deep, ask before spinning up arms.
