# abap-coding-standards

**ABAP 7.50 coding standards — a skill for writing and reviewing classic ABAP code with AI agents.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/distherion/abap-coding-standards)](https://github.com/distherion/abap-coding-standards/releases)

[Русский](README.ru.md) | [English](README.md)

A checklist for writing and reviewing
**classic ABAP 7.50 (NetWeaver)** code with AI agents: coding standards, Open SQL,
LUW/transactions, error handling, security, data types, classes, testing,
parallelism, CDS/AMDP, OData, file I/O and integration.

> **Target:** classic ABAP 7.50 (NetWeaver). **Not** ABAP Cloud / S/4HANA RAP.

## Why this skill

- **Clean ABAP + practical experience.** Rules from the SAP styleguides and verified
  SAP documentation, with real-world pitfalls and non-obvious API details.
- **Severity-aware reviews.** Every rule is tagged `[P0]`–`[P3]` so the agent reports
  findings in order of importance (blockers first, minor style notes last).
- **Load on demand.** Rules are split into `reference/*.md` by topic; the agent
  opens only the file relevant to the current task instead of the whole checklist.
- **Tool-independent.** Pure Markdown — works in Claude Code, OpenCode, Codex, Cursor,
  and any LLM via a system prompt.

## How it works

Rules use explicit markers:

| Marker       | Meaning |
|--------------|---------|
| `[P0]`–`[P3]` | Severity of a review finding (P0 = blocker … P3 = minor style) |
| `[info]`      | A fact/reference (syntax, platform, name limits); not a finding |
| `[behavior]`  | An instruction to the agent (how to search, when to ask); not a finding |

Review findings are reported in order P0 → P3:

- **P0 — Blocker:** dump, data corruption, injection / authorization bypass. Do not merge.
- **P1 — Critical:** wrong result (races, lost/corrupted money, wrong write, unhandled error).
- **P2 — Substantial:** slow (`SELECT` in loop, O(n²)), fragile, hard to test.
- **P3 — Minor:** style (naming, case, formatting, readability).

## Install

The skill is plain Markdown (`SKILL.md` + `reference/`) — the common agent-skill layout.
Copy the `abap-coding-standards/` folder into your tool's skills directory, or install it per tool:

### Claude Code

```bash
cp -r abap-coding-standards ~/.claude/skills/     # global
cp -r abap-coding-standards .claude/skills/      # project-level
```

### OpenCode

```bash
cp -r abap-coding-standards ~/.config/opencode/skills/     # global
cp -r abap-coding-standards .opencode/skills/              # project-level
```

Or reference the folder without copying, in `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "skills": { "paths": ["path/to/abap-coding-standards/abap-coding-standards"] }
}
```

### Codex

Newer Codex versions load skills from `.codex/skills/` (or via `AGENTS.md`); if yours has no skill loader — paste the rules into `AGENTS.md` or a custom prompt/agent.

### Cursor

Drop the rules into project or global `.cursor/rules/*.mdc`.

### Any LLM

Paste the relevant `reference/*.md` into the system prompt.

> Keep `abap-coding-standards/SKILL.md` and `abap-coding-standards/reference/` together.

## Repository layout

```
abap-coding-standards/
├── README.md            # documentation (English)
├── README.ru.md         # documentation (Russian)
├── LICENSE              # MIT
└── abap-coding-standards/             # the skill, in English
    ├── SKILL.md         # entry point and review workflow
    └── reference/       # topic files, loaded on demand
        ├── errors.md        # error handling, exceptions, LUW/ENQUEUE/COMMIT, update task
        ├── logging.md       # logging (cl_reca_message_list, Application Log)
        ├── data.md          # types and DDIC, numbers, date/time, tables, strings
        ├── open-sql.md      # Open SQL, performance, buffer, client, JOIN
        ├── security.md      # security, dynamic SQL, authorization, HR infotypes
        ├── classes.md       # classes, signatures, method body, DI
        ├── testing.md       # ABAP Unit: principles, test classes, doubles, assertions
        ├── parallel.md      # parallelism, bgRFC/aRFC, background jobs
        ├── cds-amdp.md      # CDS Views, AMDP (SQLScript)
        ├── dynamic-rtti.md  # dynamic programming, RTTI/RTTS
        ├── style.md         # language and style, names, booleans, formatting
        ├── odata.md         # OData (SEGW / Gateway)
        ├── files-io.md      # file I/O (DATASET, gui_upload/download, encodings, JSON/XML)
        ├── integration.md   # batch input (BDC), memory, BAdI, RFC/HTTP
        ├── ddic.md          # ABAP Dictionary: table keys, buffering, append structures, domains/DE
        ├── alv.md           # output with ALV (SAP List Viewer), classic lists
        └── local-editing.md # local editing of .abap files (encoding, block balance)
```

## Sources

The rules are distilled from the sources below. Links are kept here only — the skill itself (`SKILL.md`/`reference/`) is deliberately link-free (see `CONTRIBUTING.md`).

**SAP official**

- [Clean ABAP — SAP styleguides](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md) · [ABAP Code Reviews — SAP styleguides](https://github.com/SAP/styleguides/blob/main/abap-code-review/ABAPCodeReview.md)
- [SAP Help Portal](https://help.sap.com) · [ABAP Keyword Documentation 7.50 (ABAPDocu)](https://help.sap.com/doc/abapdocu_750_index_htm/7.50/en-US/index.htm) · [SAP Support Notes / Knowledge base](https://support.sap.com/en/my-support/knowledge-base.html)

**Static analysis & tooling**

- [SAP/code-pal-for-abap](https://github.com/SAP/code-pal-for-abap) — Clean ABAP checks in SCI/ATC
- [larshp/abapOpenChecks](https://github.com/larshp/abapOpenChecks) — open SCI/ATC checks (7.40 SP02+)
- [abaplint/abaplint](https://github.com/abaplint/abaplint) · [rules.abaplint.org](https://rules.abaplint.org) — linter for abapGit repos
- [abapGit/abapGit](https://github.com/abapGit/abapGit) — Git client for ABAP; basis of `reference/local-editing.md` and of the abapGit serialization that abaplint/SonarQube read in CI

**Learning material**

- [SAP-samples/abap-oo-basics](https://github.com/SAP-samples/abap-oo-basics) — OO basics
- [SAP-samples/abap-cheat-sheets](https://github.com/SAP-samples/abap-cheat-sheets) — ABAP syntax in a nutshell with executable demo examples
- [SchwarzIT/abap_oo_patterns](https://github.com/SchwarzIT/abap_oo_patterns) — OO design patterns
- [ilyakaznacheev/abap-best-practice](https://github.com/ilyakaznacheev/abap-best-practice) — a list of common principles of clean ABAP development
- [dotabap.org](https://dotabap.org) — ABAP open-source catalog

## Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for how to report
issues and submit pull requests.

## License

[MIT](LICENSE)