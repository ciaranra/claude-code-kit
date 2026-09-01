---
name: codex-review
description: Run an adversarial, independent Codex (OpenAI's coding-agent CLI) cross-review of a design, plan, code change, or architecture decision. Codex reads the repo read-only and attacks your claim; you cross-check and fold in the real findings. Reach for it at design forks, before building anything load-bearing, after a change to verify correctness/completeness, and for security-sensitive work — any time you want a claim independently verified rather than trusted from your own read.
---

# codex-review — adversarial Codex cross-review

Bring in Codex (`codex`, OpenAI's coding-agent CLI) as an independent, adversarial second pair of eyes.
Codex reads the repo **read-only** and attacks a claim / design / change; you then cross-check its
findings against the code, keep the real ones, refute the wrong ones, and fold the must-fixes in.

**Preflight — check these, and stop cleanly if unmet (don't fabricate a review):**
- Codex installed AND authenticated — `codex login status` (or `codex doctor`). `codex --version` only
  proves it's installed, not logged in.
- **Data boundary.** Codex sends the repo content it reads to its configured provider (OpenAI). Only run
  it on code the user is cleared to share there — read-only *filesystem* access is not confidentiality.
  For private/sensitive repos, confirm that's acceptable first.

*(The recipe below assumes a Unix-like shell; adapt paths for Windows.)*

## When to use
- A design or architecture fork — which approach; is this the *proper long-term* shape, not the expedient one.
- **Before** building something load-bearing — validate the design first (cheaper than reworking code).
- **After** a change — verify correctness AND completeness (especially security, concurrency, or anything that can silently break the wrong thing).
- Any claim you want independently verified, or when the user asks for a second opinion.

## Invocation — the mechanics that matter
From the repo root (or pass `-C <repo-root>`) so Codex resolves the file paths you cite:
```
codex exec --sandbox read-only "<prompt>" </dev/null 2>&1 | tee /tmp/codex-<topic>.md | tail -75
```
- **`--sandbox read-only`** — constrains what Codex's own shell commands may do: it reads the repo but
  won't modify your files. (The CLI still writes its own session/log state; the `tee` writes to `/tmp`.)
- **Redirect stdin `</dev/null`** when you pass the prompt as an argv string in automation: Codex appends
  piped stdin to the prompt and can otherwise wait for EOF, which in a backgrounded/harness call looks
  like a hang. This is the #1 automation gotcha.
- **Capturing output:** `tee … | tail` shows the verdict in-band (fine when the review fits); `-o
  <file>` (`--output-last-message`) captures the final message cleanly. If you pipe, `set -o pipefail`
  so a codex failure isn't hidden.
- Codex reviews take **minutes** — set a generous outer timeout (Claude Code Bash tool: `timeout:
  600000` ms; a shell `timeout` wants `10m`).
- For an actual **diff / code-change** review, the CLI has a purpose-built `codex review --uncommitted |
  --base <ref> | --commit <sha>`. Keep `codex exec` for design / claim / architecture review.
- **Scope flags reject a custom prompt** (verified on codex-cli 0.145.0, despite the usage string
  `codex review [OPTIONS] [PROMPT]`): `codex review --base dev "<instructions>"` errors with
  "the argument '--base <BRANCH>' cannot be used with '[PROMPT]'". Pick one: scoped-but-generic
  (`codex review --base <ref>`) or custom instructions via `codex exec` naming the diff yourself
  (e.g. "review the changes in `git diff <ref>...HEAD` for ..."). Re-check on CLI upgrades.

## Prompt structure — the shape that produces sharp reviews
Write ONE prompt string, built from the actual work (never a generic template):
1. **Framing** — "ADVERSARIAL review — do NOT rubber-stamp; attack it." Say what it is (design / plan / code change) and name the file(s).
2. **Context** — the setup Codex needs. It only sees the repo, so hand it the runtime facts it can't read: a live process's argv, what's deployed vs committed, off-repo consumers, the constraints.
3. **The claim to verify** — "MY FINDING / DESIGN is X. Verify or refute it from the ACTUAL code."
4. **Numbered attack tasks** — specific: correctness, completeness (every path/case), edge cases, what's MISSING, over- or under-engineering, better alternatives. Point it at exact files.
5. **Review controls** — "Actionable findings only; skip nits/style unless they affect behavior or security; give each a severity + confidence; list any assumptions or open questions."
6. **"Cite file:line."** — forces grounded, checkable findings.
7. **One-line verdict** — "End with: SHIP / REVISE / NEEDS-ADJUSTMENT / SOUND-TO-BUILD + the must-fixes."

## Handling the result
- **Cross-check every finding against the code yourself.** Codex is sharp but not infallible — keep the real ones, refute the wrong ones and say which. Report honestly which you agreed with.
- **Fold the must-fixes into a v2, then re-review.** The re-review reliably catches fresh issues (a false claim, an incomplete fix). One re-review is usually worth it; don't over-cycle.
- For a design or plan, keep the artifacts: commit the doc plus a curated review companion (verdict + findings + how each was resolved) wherever the project keeps its design records.

## Target
The user's request names the target — a design doc, a branch/diff, a specific claim, or the files to
attack. If it's unclear, ask what to review and at what depth. Always ground the prompt in the actual
work, not a template.
