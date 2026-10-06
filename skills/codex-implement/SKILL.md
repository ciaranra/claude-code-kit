---
name: codex-implement
description: Delegate a well-scoped implementation task to Codex (OpenAI's coding-agent CLI) with workspace write access, at a reasoning effort matched to the stakes, while you stay the planner, reviewer, and orchestrator. Codex writes the code; you decompose the work into task packets, review every hunk of its diff, run the verification yourself, and send findings back into the same Codex session until it meets the bar. Reach for it when the user asks to have Codex do the coding, when a task is well-specified enough to hand off, or when several independent tasks can be implemented in parallel worktrees.
---

# codex-implement — Codex codes, you orchestrate

Hand implementation to Codex (`codex`, OpenAI's coding-agent CLI) with **write access to the
workspace**, at a reasoning effort matched to the stakes. You do not stop being the
engineer: you plan and decompose, write the task packet, review the resulting diff hunk by hunk,
run the verification yourself, and iterate the same Codex session until the work meets the bar.
Codex is the implementer; you own correctness and the final quality gate.

Routing heuristic: Codex is the DEFAULT implementer — if code needs writing, the question is not
"should Codex do it" but "is the packet ready". Specification is your deliverable: turning fuzzy
intent into a decided design and a precise packet is where your judgment goes, and an
under-specified handoff is your failure, not Codex's. Bulk implementation, wide-but-shallow
changes, boilerplate, and low-stakes maintenance (deprecation warnings, lint debt,
dependency-bump fallout) are all Codex work. Write code yourself only when dispatch overhead
exceeds the task: trivial one-file edits, one-line fixes mid-review. Design, review, API taste,
and anything still ambiguous stay with you — resolve the ambiguity, then dispatch.

**Preflight — check these, and stop cleanly if unmet:**
- Codex installed AND authenticated — `codex login status` (or `codex doctor`).
- **Data boundary.** Codex sends repo content to its provider (OpenAI). Only run it on code the
  user is cleared to share there. For private/sensitive repos, confirm first.
- **Clean starting state.** `git status` must be clean (or the pre-existing changes committed or
  stashed) before dispatch, so Codex's diff is exactly attributable and cleanly revertible. Never
  let it work on top of unrelated uncommitted changes.
- **Design is settled.** Codex implements a plan; it should not be discovering the architecture.
  If the design is still open, resolve it first (optionally via `/codex-review` on the design).

## Dispatch — the mechanics that matter
From the repo root (or `-C <repo-root>`):
```
codex exec --sandbox workspace-write \
  -c model_reasoning_effort="medium" \
  -o /tmp/codex-<task>-last.md \
  "<task packet>" </dev/null 2>&1 | tee /tmp/codex-<task>.log | tail -40
```
- **`--sandbox workspace-write`** — Codex may edit files and run commands inside the workspace,
  nothing outside it. Its **network is off by default** in this mode: builds that fetch
  dependencies (cargo, uv, npm) will fail unless you pre-warm caches first (`cargo fetch`,
  `uv sync`) — preferred — or, if fetching mid-task is unavoidable, add
  `-c sandbox_workspace_write.network_access=true`.
- **Pin `service_tier` and `model_reasoning_effort` explicitly** rather than relying on
  `~/.codex/config.toml`. Never pin a model ID — the config owns that, and hardcoded model names go
  stale silently.
- **Effort: `medium` for routine implementation, `high` for correctness-sensitive or debugging work.
  Treat `xhigh` and `max` as exceptional, not as "more careful".** OpenAI's guidance is agentic
  coding at medium, complex debugging at high, xhigh "only when your evals show a clear benefit".

  **More effort is not monotonically better, and can be worse.** Excessive test-time reasoning
  yields diminishing returns and can cause a model to *abandon previously correct answers*. Coding
  agents specifically show three overthinking failure modes: analysis paralysis (planning at length
  while making little progress), rogue actions (firing several actions at once), and premature
  disengagement (stopping on an internal prediction instead of environment feedback). One study
  varying thinking effort across four levels found no significant effect on avoiding unnecessary
  edits — 61.5% to 65.8%. In one code-review test, `high` found no more bugs than `low`.

  Cost per task climbs steeply regardless: low $0.63 / medium $1.16 / high $1.41 / xhigh $1.85 /
  max $2.57, for index 49/52/53/54/55. On SWE-style work, o1 at high effort resolved 29.1% for
  $1,400 against 21.0% for $400 at low — 3.5x the cost for 8 points.

  **When output quality is the problem, fix the packet, not the effort.** A sharper contract, a
  named oracle, an explicit verification bar, and a "stop and report rather than deviate" escape
  hatch all beat turning the dial up — and unlike effort they cannot induce overthinking. Reserve
  xhigh for work that is genuinely enumerative and wide (auditing every call site, a mutation sweep
  across many guards), where the risk is *missing* something rather than *reasoning past* it.
  "This task feels important" is not a reason.

  (Learned 2026-09-05: pinning xhigh on every dispatch exhausted the usage limit mid-session and
  stalled two in-flight rounds. Every genuine quality win that session came from a better packet —
  explicit oracles, mutation requirements, forbidden regeneration of reference data — not from
  effort.)
- **Service tier: `fast` doubles the cost.** Use it only when you are blocked on the result. For a
  backgrounded packet where you end the turn and wait for the notification, latency is free — the
  default tier is the better trade.
- **Redirect stdin `</dev/null`** when passing the prompt as an argv string — otherwise Codex may
  wait on piped stdin for EOF and look hung. The #1 automation gotcha.
- Implementation runs take **minutes to tens of minutes** — use a generous timeout
  (Bash tool: `timeout: 600000`) or `run_in_background: true` for big packets, then keep planning
  the next packet while it works. After a background dispatch, end the turn — completion notifies
  you; don't sleep, poll, or arm a monitor for it.
- **Grab the session id** from the header of the log (`session id: <uuid>`) so review feedback can
  resume the exact session even if other codex runs happen in between. `--last` works only when
  nothing else ran since. Resume syntax: flags go BEFORE the subcommand —
  `codex exec --sandbox workspace-write -c ... -o <file> resume <session-id> "<feedback>"`;
  flags placed after `resume` are rejected with "unexpected argument".
- **Context hygiene:** Codex streams its full reasoning to stderr. Keep the complete `tee` log on
  disk for debugging, but read back only the `-o` last-message file and the git diff — never pull
  the raw log into context.
- **Ponytail mode (experimental):** for a small, self-contained cleanup packet (lint debt, small
  mechanical fixes) where a reuse-first, minimum-code bias helps, prepend the body of
  the `ponytail` agent to the packet. Never for boundary/threshold, oracle-sensitive, or
  load-bearing work.

## The task packet — what a good handoff contains
One prompt string, built from the actual work (never a generic template). Hand Codex a **contract,
not an edit-list**: the outcome, the invariants, and how it will be judged — then let it inspect the
repo and find the implementation. Current frontier coding agents do better given goal + tests
+ freedom to explore than given a prescribed sequence of edits, and over-specifying *guessed* files
measurably degrades them — pin exact paths only where they are a real constraint (a file that must
NOT change, a known-good reference to match).
1. **Goal + definition of done** — what to build and how you'll judge it finished. Concrete: which
   behavior, which API shape, which tests must pass.
2. **Context** — the files genuinely involved (exact paths only where they're a real constraint,
   not guessed), the surrounding architecture, and the design decisions already made. State
   plainly: "The design is decided; implement it. If you believe it is wrong, STOP and say why in
   your final message instead of silently deviating."
3. **Constraints** — the house rules that bind this task: match surrounding style and idiom; no
   new dependencies without flagging; no fallbacks, workarounds, or lint suppressions to force
   green — if stuck, stop and report; **do NOT `git commit`, `git push`, or otherwise touch git
   history — leave everything as uncommitted working-tree changes.**
   Every packet also carries this canonical block VERBATIM (mandatory countermeasure to
   task-closure bias; do not paraphrase or drop it):
   > Before editing, trace the affected behavior end to end and search for existing repo
   > primitives, standard-library/platform facilities, and already-installed dependencies that
   > satisfy the decided design. Reuse them; do not reopen or substitute the design.
   > Fix the invariant at the layer that owns it, not only the named or tested path — inspect
   > every caller, analogous occurrence, and newly reachable downstream helper.
   > Optimize for the full stated contract, not the smallest diff or the supplied examples.
   > Tests are evidence, not the boundary; prefer the smallest complete correct change only
   > after establishing correctness.
4. **Verification** — the exact commands to run (test filter, lint, build) and the requirement
   that they pass before reporting done. For a behavior-changing bug fix, the packet also states
   which regression test will demonstrate the contract — or cites the existing coverage that
   already does, or why a new test is infeasible. Reference data stays orchestrator-owned (see
   "Never let it own its oracle" below).
5. **Report format** — final message: files changed, verification commands run + their results,
   any deviations from the packet, open questions. Not prose about how it went.

For a LOAD-BEARING packet, review the reviewer's blind spot — yourself: before dispatch, run a
quick /codex-review of the packet text against the design source ("does this packet faithfully
encode the spec? attack my interpretations of anything ambiguous"). Every downstream gate
verifies against the packet; a wrong packet defeats them all.

## Steering Codex — learned countermeasures (append as new ones are earned)
Codex's characteristic failure is task-closure bias ("get the ticket closed"): the minimum change
that satisfies the stated acceptance criteria, not the underlying contract. Counter it in the
packet, not the review:
- **Boundary/regime work**: demand VALIDATED bounds ("sweep until the method genuinely stops
  meeting tolerance, place the gate with margin, document the validated bound") and per-region
  worst-error reporting from its own probes — otherwise it will place thresholds just past your
  test cases, and the defect moves instead of dying (observed three rounds running, 2026-07-06).
- **Reporting**: require an explicit deviation list "including ones you consider benign" — an
  unqualified "deviations: none" from Codex has been observed false while effects were benign.
- **Never let it own its oracle**: test fixtures/reference data are generated and committed by
  the orchestrator before dispatch, marked untouchable in the packet.
- **Pattern claims need receipts**: when Codex justifies a choice as following "an existing
  pattern", the report must cite where that pattern lives (file:line) — a fabricated
  "existing tuple pattern" justification was observed dressing up a lint-silencing fix
  (2026-07-11). Grep the claim during review; an uncited pattern claim is treated as false.
- **When a gate/regime widens, the helpers behind it are new code too**: a boundary change sends
  previously-impossible values through downstream janitor functions (clamps, snaps, validators)
  nobody re-checked — demand the packet re-validate helper behavior over the newly reachable
  range, and test primitives DIRECTLY, not only through the higher-level paths that happen to
  dodge them (observed: a clamp-ordering bug survived four review rounds because the tests
  structurally never exercised the primitive at saturation, 2026-07-06).
- **An invariant guard covers every consumer of the guarded type, not just the type's own
  methods**: when a fix adds a validity flag/guard to a data object, demand enumeration of ALL
  entry points that accept that object (grep the parameter type) and a test on at least one
  consumer-side path — a validity guard was added to all six of the data object's own methods
  while five separate consumers taking that object by reference silently bypassed it; only an
  adversarial re-review caught it because the one test covered the object's own method
  (2026-08-06).
- **When the packet prescribes a specific existing helper, the packet owns that helper's
  semantics**: a packet ordered a summation to "accumulate via the existing add-term helper";
  Codex complied faithfully, and that helper's user-facing drop-below-tolerance guard silently
  discarded sub-tolerance contributions before they could sum — a real defect authored by the
  PACKET, invisible to hunk review because the diff matched the spec (2026-08-21,
  caught only by a fresh-context review arm). Prescribe the CONTRACT ("final coefficients are
  summed, then tolerance-dropped once"), not the helper; if you do name a helper for an
  internal role, first verify its semantics fit that role and say in the packet why. This is
  the sharp edge of "contract, not edit-list": an edit-list can inject bugs, not just degrade
  exploration.
- **Never enumerate a set the repo already defines — cite the predicate**: a packet spelled out
  the members of a "transparent" set from memory of an enum, while the module already defined
  two predicate functions stating exactly that set; the packet's list silently omitted two
  variants, Codex implemented it faithfully, and the result rejected every input built by the
  project's own generators (2026-08-25). The full test suite passed because the
  omitted variants only appear on a path those tests do not build. Before writing any explicit
  set/list/threshold into a packet, grep for an existing predicate that defines it and cite that
  instead — and when the fix lands, require the classification to READ the shared definition
  rather than copy it, or the packet has just authored the duplication it was sent to remove.
- **A behaviour the packet asserts becomes a licence to move any fence in its way**: a packet
  said from memory that inputs already containing noise channels "pass through the noise-applying
  path unchanged"; the owner layer deliberately REJECTS such inputs, and Codex loosened that core
  rule to satisfy the packet, reporting it as a "required owner-layer extension" (2026-09-19).
  Before stating how an existing path behaves, read that path; if it contradicts the packet, the
  packet is wrong. And when a report lists an owner-layer change the packet never asked for, treat
  it as a fence moved, not a deviation.
- **Put the guard where CI runs it**: Codex placed an exhaustive classification test as a unit
  test in a crate the CI recipe excludes from its test run (11 failures there had been invisible
  for that reason). A guard that never runs is documentation. Check which packages the CI recipe
  actually tests before accepting the test's location, and put shared logic in a package CI tests
  so its test is live.

- **Scope every stop condition to its own contract**: a packet with six contracts said of one of
  them "if no such entry point exists, stop and report rather than inventing one"; Codex found the
  entry point missing and stopped the WHOLE packet with zero edits, costing a full round
  (2026-09-21). Write "skip THIS contract, report it, and complete the others" unless the missing
  piece genuinely blocks the rest. And when a packet is built from a grep of file paths rather
  than a read of the structure, expect a clean stop on scope: name packages, not files, and state
  which layer owns each mapping (a converter file the grep never matched held the real one).

- **A report that mentions stashing and restoring the tree means wait before verifying**: an arm
  that ran its own baseline by moving files aside and restoring them "byte-for-byte" reported all
  green; verification started immediately after the report and hit a compile error (a method the
  diff plainly added was "not found"), then the same command passed minutes later with no edit
  (2026-09-27). The first run had read the tree mid-restore. When a report mentions stashing,
  snapshotting or restoring, re-read one changed file and re-run rather than trusting either the
  green claim or the red first result — and never conclude "flaky" from a pass on the second try:
  force the caches cold (touch the changed files) and get a clean run you can cite.

- **"Reject X" must say whether ABSENT counts as X**: a findings note said "reject a declaration
  whose `data_type` is not \"qubits\"", Codex implemented `get("data_type") != Some("qubits")`, and
  an omitted field — which the format's own spec marks optional — became a hard error, breaking a
  documented example (2026-09-27). Whenever a packet or a findings note asks for validation, state
  the three cases separately: absent, present-and-valid, present-and-invalid, and cite the spec
  line that says which of them is legal. The same trap applies to empty strings, empty lists and
  zero.

- **Never describe existing code from memory in a packet — open the lines and quote them**: three
  consecutive packets in one session each contained a factual error about code the packet was
  built around (a converter file the grep never matched held the real mapping; a helper described
  as consuming a foreign-interface enum actually consumed an IR op; an emission described as
  including a shift by zero when the helper skips it for bit zero). Every one produced a clean
  STOP and cost a round (2026-09-27). The tell is a packet sentence of the form "X currently does
  Y" written without a `sed -n` of X in that turn. Read the exact lines, or state the claim as an
  assumption for the arm to check first.

- **A report line that calls an external constraint "incorrect" is a workaround confessing
  itself**: an arm decided a zero-size register should be accepted, found the upstream pydantic
  schema rejects it (`Gt(gt=0)`), declared the schema "incorrectly requires a strictly positive
  size", and filtered those operations out of schema validation — disabling upstream validation
  for that whole operation kind so its own new test would pass (2026-09-27). Nothing in the packet
  asked for zero to be legal. Grep every report for phrases like "incorrectly", "the schema is
  wrong", "upstream disagrees", "does not support", and go read the external constraint yourself:
  it is usually right, and the arm has usually just invented the requirement it is fighting.
  Related to the fence rule above — the packet asserts, the arm removes whatever blocks the
  assertion.

- **Label every prescribed test as red/green or compatibility, and pin its expected output to the
  code path, not to intuition**: a packet asked for three tests and one blanket "each must fail on
  the pre-fix code"; Codex stopped twice, once because a test expectation contradicted the code
  (the branch under test never applied the operation the expectation assumed, so the described
  state was impossible) and once because a captured-bytes compatibility test cannot fail on both
  versions by definition (2026-09-02). Both stops were correct. Before writing a test expectation
  into a packet, trace that scenario through the actual branch; mark which tests demonstrate the
  fix and which pin unchanged behavior; and add "when a packet detail is merely underspecified
  rather than contradicting the code, choose the reading that preserves the contract, proceed, and
  list the choice under deviations."

- **Never name an existing error variant, helper, or type for a meaning it does not have**: a
  packet told Codex to reuse an existing angle-arity error variant for a qubit-count mismatch;
  Codex complied and the Display text lied (2026-09-04, caught only at hunk review). Same class as
  the add-term defect: prescribe the meaning ("a qubit-count mismatch is its own error with a
  truthful message") and let the implementer pick or add the variant.
- **"No fallible operation on that path" must be checked for panics, not just `Result`s**: a
  reviewer (and the packet built on it) declared a sampling path infallible because nothing
  returned `Err`; the executor `assert!`ed and `panic!`ed on unsupported gates instead
  (2026-09-04). When scoping error propagation, grep `assert!|panic!|expect(|unwrap()` on every
  executor the contract covers before writing "leave it alone".

## Review loop — where the quality actually comes from
Tier the depth to the stakes. **Low-stakes packets** (docs, lint debt, mechanical migrations with
strong tests): the `qa-verifier` agent's evidence-based PASS plus your own scope check
(`git diff --stat`, skim for suppressions) is the gate — don't read every hunk. **Load-bearing
packets** (numerics, concurrency, public API, anything a wrong answer silently corrupts): the
full loop below, every hunk, plus an independent adversarial arm. When unsure, take the deeper
tier.
1. When Codex returns, read its report, then ignore its self-assessment and check the ground
   truth: `git status` + `git diff` — **review every hunk** against the packet (correctness,
   completeness, style match, nothing out of scope touched, no sneaked-in suppressions or
   fallbacks).
2. **Re-run the verification yourself** — tests, lint, build. Codex claiming green is not green.
   For a large packet, dispatch the `qa-verifier` agent with the packet and Codex's report — a
   fresh-context verifier outperforms in-context self-checking.
3. Triage:
   - **Trivial nits** — fix them directly yourself; not worth a round-trip.
   - **Substantive issues** — send findings back into the same session so it keeps its context:
     `codex exec -C <repo-root> --sandbox workspace-write [-c ...] resume <session-id> "<numbered findings, cite file:line>" </dev/null`
     Two resume gotchas, both live-caught: flags belong to `exec` and MUST come **before** the
     `resume` subcommand (after it they error); and `-C` MUST be repeated — a resumed session
     roots its write sandbox at the orchestrator's current cwd, not the session's original
     workdir, so omitting `-C` can point Codex's write access at the wrong repo. For long
     findings, `"$(cat <findings-file>)"` — and Write the file before referencing it.
     One or two round-trips is normal. If it's thrashing on the third, take over and finish it
     yourself — say so honestly in your report.
   - **Wrong wholesale** — revert (`git checkout -- .` is safe *because* you started clean) and
     either re-dispatch with a sharper packet or implement it yourself.
4. For load-bearing changes, add an independent adversarial pass before shipping — `/codex-review`
   on the diff or `/deep-review` — same standard as code you wrote by hand.
5. Report to the user which parts Codex wrote, what you fixed or rejected, and how it was
   verified. Commit only when the user asks, as ever.

## Parallel packets
Independent tasks can run concurrently: one git worktree per task, one backgrounded `codex exec -C
<worktree>` each. Review and integrate them **sequentially** — parallel implementation is cheap,
parallel unreviewed merging is how conflicts and regressions slip in.

⚠️ **Concurrency caveat (learned 2026-07-14)**: under ChatGPT-login OAuth, concurrent `codex`
instances share `~/.codex/auth.json` and race its single-use rotating refresh token
(openai/codex#10332). If the access token needs refreshing at launch, racing instances wedge
silently (alive, zero CPU, no writes under `~/.codex`) — works most days, then deadlocks.
For real fan-out use the VERIFIED isolated-home recipe (tested 2026-07-14: simultaneous execs
completed, no cross-revocation): a second identity at `~/.codex-arm2` (one-time
`mkdir ~/.codex-arm2 && CODEX_HOME=$HOME/.codex-arm2 codex login`), then run the second packet as
`CODEX_HOME=$HOME/.codex-arm2 codex exec -C <worktree> ...`. Same ChatGPT subscription covers both.
**`CODEX_HOME` must be repeated on `resume`, exactly like `-C`** (live-caught 2026-08-25): session
history lives under the home that created it, so resuming an isolated-home session without the var
fails with `thread/resume failed: no rollout found for thread id <uuid> (code -32600)`. That error
goes to the log while the surrounding shell command still reports success, so a backgrounded resume
looks like it completed — always read the `-o` file, and treat its absence as a failed dispatch.
With one home only: stagger launches (start packet N+1 after N visibly produces output) or run
sequentially.

Inside a Workflow script or subagent fan-out (where you can't background a Bash call yourself),
wrap each dispatch in a thin, cheap subagent — sonnet or haiku at low effort — whose only job is
to run the `codex exec` command, wait, and return Codex's final report plus `git diff --stat`.
The orchestrator stays out of the loop until the work is done, then reviews as usual.

## When NOT to use
- Tiny or one-file edits — dispatching, reviewing, and round-tripping costs more than doing it.
- Ambiguous or design-heavy work — settle the design first; Codex gets a decided plan.
- Anything the user isn't cleared to send to OpenAI.
