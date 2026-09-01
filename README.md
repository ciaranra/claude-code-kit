# claude-code-kit

Agents and skills for [Claude Code](https://claude.com/claude-code), extracted from a working
setup. Everything here is general-purpose — no project, employer, or infrastructure specifics.

Two ideas run through all of it: **delegate the mechanical work and keep the judgment**, and
**verify claims instead of trusting reports** — your own included.

## Acknowledgements

This kit stands on other people's work, and two agents are largely theirs:

- **[grugbrain.dev](https://grugbrain.dev)** by Carson Gross — the complexity demon, the magic
  word "no", Chesterton's fence, FOLD. `grug-scout` is that philosophy turned into a reviewer,
  and `tiger-grug` takes its pragmatic half from the same place.
- **[DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)** — the `ponytail`
  agent is that project's prompt, near-verbatim, with a house-rules paragraph swapped in for its
  closing line.
- **[TigerBeetle's Tiger Style](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)**
  — the safety half of `tiger-grug`: bounds on everything, assertions, naming discipline,
  performance considered at design time.

Upstream licenses and notices are reproduced in
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

## Skills

| Skill | What it does |
| --- | --- |
| `codex-scout` | Read-only reconnaissance, usage inventories, subsystem summaries, and first drafts, handed to the Codex CLI so they don't cost your context. |
| `codex-implement` | Full delegation loop for implementation work: you write the task packet, Codex writes the code, you review every hunk and re-run the verification yourself. Carries a growing list of learned countermeasures against task-closure bias. |
| `codex-review` | Adversarial, independent cross-review of a design, plan, or diff by a different model. |
| `deep-review` | Multi-reviewer panel for high-stakes changes: independent arms along different axes (fresh context, different model, different lens), fused by merit rather than by vote. |
| `deep-research` | The same panel protocol aimed at research questions, where the failure mode is a stale training prior rather than a subtle bug. |
| `retro` | Mines recent sessions for recurring friction and converts each pattern into the smallest durable fix. |

The `codex-*` skills and the cross-model arm of the `deep-*` skills assume the
[Codex CLI](https://github.com/openai/codex) is installed and logged in. Each one checks the data
boundary first: Codex sends repo content to OpenAI, so they are only for code you are cleared to
share there.

## Agents

| Agent | What it does |
| --- | --- |
| `qa-verifier` | Fresh-context verification engineer. Takes a spec plus a claim that the work is done, re-runs everything itself, and returns a PASS / PASS-WITH-CONCERNS / FAIL verdict where every claim cites a command it actually ran. It never fixes anything. |
| `tiger-grug` | Code reviewer combining Tiger Style discipline with grug-brain pragmatism. |
| `grug-scout` | Advisory reviewer that evaluates code and architecture purely through grug philosophy. |
| `ponytail` | "Lazy senior developer" implementer with a reuse-first, minimum-code bias. |

## Install

```bash
git clone https://github.com/ciaranra/claude-code-kit.git
cd claude-code-kit
./install.sh
```

`install.sh` copies `agents/` and `skills/` into `~/.claude/`, backing up anything it replaces
into `~/.claude/backups/claude-code-kit-<timestamp>/`. It writes nothing else — your
`settings.json` is left alone. Restart Claude Code afterwards.

To take just one piece, copy that file: an agent goes at `~/.claude/agents/<name>.md`, a skill at
`~/.claude/skills/<name>/SKILL.md`. Per-project copies live under `.claude/` in the repo instead.

## License

MIT for the original material here — see [LICENSE](LICENSE). Derived material keeps its upstream
license, recorded in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
