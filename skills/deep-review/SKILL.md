---
name: deep-review
description: For high-stakes changes — load-bearing code, security, concurrency, architecture forks — run an independent multi-reviewer panel and fuse the findings by merit, rather than trusting a single review (including your own). Assemble reviewers along diverse axes of independence — a fresh subagent (no context-bias), a different model (e.g. Codex, catches cross-model blind spots), optionally a different lens — each adversarial and blind to each other and to your conclusions; then cross-check every finding against the code and synthesize: corroboration raises confidence, a solo finding is the sharp non-overlapping catch, a conflict is the thing to investigate. Scales from two arms up. Use when being wrong is expensive and correctness is worth the extra cost; for routine changes, a single codex-review is plenty.
---

# deep-review — independent multi-reviewer panel, fused by merit

For work where being wrong is expensive — a load-bearing component, a security or concurrency change,
an architecture fork — don't trust a single review (including your own). Run an **independent panel of
adversarial reviewers** and **fuse their findings by merit**. Reviewers from *different vantage points*
catch more than any one alone; you (the orchestrator) cross-check everything against the code and
synthesize one grounded verdict.

**When to use — high-stakes only.** A load-bearing/shared component, anything security- or
concurrency-sensitive, an architecture decision, or a change that can silently break the wrong thing.
For routine changes, a single `codex-review` is enough — a panel costs more.

## The principle: diverse axes of independence, fused by merit
One reviewer has one set of blind spots. A panel wins when its reviewers are independent along
*different axes* — each axis you add is coverage the others can't provide:
- **Fresh context** — a fresh subagent: no priming, no fatigue, none of the context-bias you build up
  living in a change for hours. Catches what you overlook.
- **Different model** — a non-Claude reviewer (e.g. Codex) has different training and different failure
  modes; it flags what a Claude-family reviewer systematically underweights. Measure independence
  FROM THE AUTHOR: if Codex wrote the change (e.g. via /codex-implement), a Codex arm loses most of
  its value — models measurably self-endorse their own bugs — so the cross-model axis flips to
  Claude-side arms, with a fresh-session Codex pass as optional extra, not as the independent arm.
- **Different lens** (optional) — a reviewer aimed at one dimension (security, concurrency, API
  contracts) goes deeper there than a generalist pass.

You are always the **fuser**, never just another reviewer: context-rich but possibly biased/fatigued,
so your job is to weigh, not to vote.

## Assemble the panel — in parallel, and BLIND
Kick all arms off at once (one message, concurrent), each given only the target + the claim to verify —
**NOT your analysis, your conclusions, or another reviewer's output.** Anchoring destroys the
independence that makes the panel worth running.

The **high-value default is two arms** — they cover the two biggest axes:
- **Fresh-context arm** — spin up a fresh subagent via the Agent tool (`general-purpose`, or a
  code-reviewer agent type if your setup has one). Prompt it adversarially: "Independently review
  <target>. Attack it — correctness, completeness, every edge case, what's MISSING, security/
  concurrency. Cite file:line, severity + confidence per finding. Don't rubber-stamp." Hand it the files
  + the claim, nothing of your own read.
- **Cross-model arm** — run a `codex-review` against the same target with an equivalent adversarial
  prompt (see the `codex-review` skill for invocation + the data-boundary check).

**Scale up when the stakes justify it:** add another model's CLI, another fresh subagent aimed at a
different lens, or a second pass at higher effort. The protocol below is identical for N arms and for two.

## Fuse by merit — the actual work
Collect every arm's review, then **cross-check each finding against the real code yourself** — the panel
proposes, you dispose. Sort each finding:
- **Corroborated** (flagged by two or more arms) → high confidence; act on it.
- **Solo** (one arm only) → this is the *non-overlapping coverage you ran the panel for* — the sharpest
  catches often come from a single arm. Evaluate on merit; do NOT discount it for being solo.
- **Conflict** (one arm says fine, another says broken) → the most informative signal; investigate,
  resolve it against the code, and report which was right and why.

Then dedupe overlaps (same issue in different words), refute the wrong findings and say why, and
synthesize **one merged verdict + a deduped, severity-ranked must-fix list**. Close with a quick "what
might ALL of them have missed?" — a blind spot shared across every arm is the panel's one real weakness.

## After
- Fold the must-fixes, then **re-review** — at least the cross-model arm; a full re-panel for the
  riskiest changes. The re-review reliably catches a bad fix or a fresh issue. Don't over-cycle.
- For high-stakes work, keep the artifacts: each arm's raw review + your fusion (verdict, findings, how
  each was resolved), wherever the project keeps its design/review records.

## Target
The user's request names the target — a design doc, a branch/diff, a component, or a specific claim. If
it's unclear, ask what to review and how deep. Always ground every arm in the actual work, never a
template.
