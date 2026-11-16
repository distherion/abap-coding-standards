---
name: abap-coding-standards
description: Rules for writing and reviewing ABAP 7.50 (SAP) code — coding standards, Clean ABAP, error handling, LUW/COMMIT, AUTHORITY-CHECK, DDIC, internal tables, Open SQL, CDS/AMDP, HR infotypes (PA/OM/PD), BAPI/RFC. Apply when editing .abap files or abapGit exports; when reviewing, auditing or refactoring a diff, class, method, function module, report, BAdI or enhancement; when fixing a short dump (ST22) or an ATC/abaplint finding; and when the user mentions ABAP, SAP, SE80/ADT, abapGit, or asks in Russian — "отревью", "правь метод", "отчёт ABAP", "инфотип". Targets NetWeaver 7.50 — no post-7.50 statements or types. Not for the SAP frontend (Fiori/SAPUI5, Web Dynpro), output forms (Smart Forms/Adobe), IDoc/ALE, BW/analytics, or ABAP Cloud.
compatibility: Target SAP NetWeaver 7.50 (ABAP). No runtime dependencies, no network access needed.
metadata:
  lang: en
---

# ABAP — rules and constraints

> Skill `abap-coding-standards` (ABAP 7.50), extended with Clean ABAP rules (SAP styleguides).
> A statement true only from a later release is marked inline `(7.5x+)` (e.g. `(7.54+)`; an older, still-valid one — `(7.40+)`) and collected in `reference/style.md`, "Version: what is NOT in 7.50".
> Rules are split by topic into `reference/*.md` — open only the file for the current topic (see "Reference map").

## Review vs own code
- **Own code** = code you write/edit yourself (new diff, new methods) — follow all rules strictly.
- **Others' code** = existing legacy / review without edits — a factual error or a wrong result is a finding at its **usual severity**; only purely stylistic rules (`SELECT *`, `WITH DEFAULT KEY`, case/formatting/pretty-printer) fall to P3.
- Unclear — ask.
- **Project convention wins over this skill** where the project has one (an in-house wrapper, a deliberate older form, a documented repo standard, an agreed exception — e.g. `itab.md`: "we prefer `ASSIGNING`"). Follow it and name the rule you depart from; the convention never excuses a defect: a wrong result, a lost write or a bypassed authorization stays a finding.

## Refactoring legacy
- **[behavior]** Boy scout rule: touch a piece of code — leave it cleaner (a small rule-compliant fix, not a large rewrite). Clean islands: new code clean, the surrounding legacy not rewritten in the same change.
- **[behavior]** Do not mix styles in one object: new code in a legacy object follows the new rules; the whole object is not migrated at once.
- **[behavior]** A refactor of someone else's or shared code — agree with the team first.

## Priorities — severity levels on review

- **P0 — Blocker**: a dump on a supported, expected execution path; data corruption; injection / authorization bypass — do not merge until fixed.
- **P1 — Critical**: wrong result (races, lost/corrupted money, wrong write, unhandled error) — must fix. A dump caused only by invalid input or an out-of-contract API call is normally P1; state the concrete invalid state and where it must be rejected.
- **P2 — Substantial**: slow (`SELECT` in loop, O(n²)), fragile, hard to test — worth fixing, a separate task is fine.
- **P3 — Minor**: style (naming, case, formatting); others' code — per "Review vs own code". In passing or skip.
- **Downgraded (P2 → P3, in passing; never below P2 without explicit context):** two cases only, both `errors.md` (`[P2]` — "Write under a lock", "COMMIT in chunks"): a write without `ENQUEUE/DEQUEUE` where concurrency is provably impossible (single-user dialog/report — an unobserved race is not proof); `COMMIT` in chunks in mass loading where every chunk is self-consistent.
- **Exception to that downgrade — broken LUW (P1):** one money/data operation split into independent `COMMIT`s: an interruption leaves a half-saved state — a payment without its items, a header without its rows, an error swallowed while `COMMIT` still runs. A defect, not "COMMIT in a loop".

**Markers** start a rule: `[P#]` — severity on review; `[info]` — background (syntax, platform, name limits), not a finding — do not report, but its claims are verified like any other ("Finding sources"); `[behavior]` — an instruction to the agent (how to search, when to ask, what to edit), not a code finding. Inside a rule the lead-in `**does not exist:**` marks a claim that an API, parameter or statement does **not** exist — verified like any other claim, and the class that keeps an invented API out of the code (`MAINTENANCE.md`).

**Citing a rule in a report:** P0/P1 rules carry a stable slug in a trailing HTML comment (`rule:` + slug, invisible) — machine-searchable, **not** an anchor: cite rules point-in-time as `file.md:line` (e.g. `errors.md:19`) and name the slug in parentheses. Slugs are unique per file; P2/P3/`[info]` have none — cite by `file.md:line`. Code evidence is cited by object, never as `x.abap:190`.

## Review flow
1. Verify references and logic ("Context — don't invent", "Logic above rules").
2. Run the checklist by topic (open the relevant `reference/*.md`) and assign each finding a level.
3. Report in order P0 → P3.

## Review report
The report: findings in severity order, then what was covered and not.

- **[behavior]** One finding — one line: **`<severity> <object> (<rule:slug>) — what breaks (scenario: input/state → wrong result) — fix`**. The location is the code **object** — `FORM roav`, method `transfer` of `ZCL_07EC_ZRET_RESERVES`, FM, class — never a line number: a line moves with every export and is unreadable outside it. P0/P1 — with the scenario; P2/P3 — defect and fix.
- **[behavior]** Quote the shortest decisive fragment of the code, not a paraphrase of the rule; no praise, no restating a rule that is not violated. No concrete fix — a remark, not a finding: keep it out or mark it a question.
- **[behavior]** Close with two lines: `Checked: <files and areas>` / `Not checked: <what was left out and why>` (the missing local syntax check — activation happens in SAP — belongs there). No findings — say so with the same two lines: an empty report reads as a review of everything.

## Logic above rules
Look for logic errors beyond the rules — they are a minimal checklist, not an exhaustive list. Beyond them: races and wrong call order, lost/stuck states, edge cases (empty inputs, short strings, invalid dates, missing records), silent failures, double/extra side effects, mismatch between caller and callee, unset flags/statuses. Any such finding gets a level P0–P3 and a concrete fix.

## Finding sources
- **[behavior]** In doubt about an API, standard SAP behavior, the semantics of an FM/class/infotype, syntax or ABAP limits — check the documentation first, with network access: SAP Help Portal / ABAPDocu / SAP Notes, then Stack Overflow / SAP Community. Do not invent.

## Context — don't invent
- **[behavior]** Do not invent DDIC structures/tables/interfaces/classes/FMs, fields and signatures. No definition or not enough context (inheritance hierarchy, BAdI points) — **ask a clarifying question** before writing code.
- **[behavior]** Verify actual method/component names against the code, not by assumption.
- **[behavior]** **On review, verify every reference against its definition in the repo, do not trust what is written**: `MESSAGE eNNN(class)` ↔ `.msag.xml` (number exists, `&1..&4` matches `WITH`; a stale number is P2, `errors.md:32`); class/interface/FM/method names ↔ the declaration (`.clas.abap`/`.intf.abap`/`.fugr.*`/`.prog.*`); fields/components ↔ `TYPES`/`.tabl.xml`; call signature ↔ method declaration. A mismatch is P0–P2; no definition — "context missing, verify", do not assume.

## Automated checks
- **[behavior]** Run static analyzers as part of the review — they catch their defined set (naming, syntax, anti-patterns); logic, races, LUW need the manual pass. In-system — ATC (Code Inspector); on abapGit — abaplint (`abaplint.json`), code pal, abapOpenChecks, SonarSource ABAP. Before writing your own utility, check the ecosystem.
- **[behavior]** A green abaplint run is not "it activates": with `check_syntax` and enough source context it detects undeclared identifiers; it replaces neither activation in the target release nor the FM actual/formal type check — a mismatch fails at runtime (`signatures.md`, `formal-param-type-subset`, `fm-param-type-exact`). Say so when handing code over.
- **[behavior]** Outside an ABAP system abaplint resolves names only from the config's dependencies (abapGit exports of the called packages); without them every unresolved class, FM, field or table is a finding about the **sandbox**, not the code. No-dependency checks (naming, syntax, structure, anti-patterns) stand; the `Unknown ...` family is verified against a definition or dropped — its raw count is not a review result. Export artifacts (a `.g4bs.xml` fragment, an unmodelled statement) read as findings too.

## Local editing of `.abap` files

- **[behavior]** Files are an abapGit export: UTF-8 + LF, Cyrillic written directly (no `\u04XX`-escapes); legacy cp1251+CRLF files — rewrite entirely via Write.
- **[behavior]** Edit `.abap` files with your own file-editing tools — never through shell text utilities (`iconv`/`sed`/`awk` on unix, PowerShell/cmd on Windows). Local syntax check is unavailable — activation happens in SAP; say so in the output.
- **[behavior]** Every ABAP source identifier (types included) is limited to 30 characters (`reference/naming.md`). Declare locals near first use; predeclare a typed local for method/FM output actuals (explicit `TYPE REF TO` for class references); prefer a functional call for non-reference `RETURNING` values. See `reference/data.md`, `reference/signatures.md`; do not mass-migrate legacy code.
- **[behavior]** After edits, check the block balance: `METHOD/ENDMETHOD`, `TRY/ENDTRY`, `IF/ENDIF`, `LOOP/ENDLOOP`, `CASE/ENDCASE`, `DO/ENDDO`.
- **[P3]** SE24 adds a `* <SIGNATURE>` method header; an abapGit export has none — do not expect or remove it.
- **[behavior]** A table field symbol needs an explicit `FIELD-SYMBOLS ... TYPE ANY/STANDARD TABLE` near its binding — inline `FIELD-SYMBOL(...)` cannot express a table type (`reference/dynamic-rtti.md`).

## Reference map
Open only the file for the topic at hand:

| When the task touches… | Open |
|------------------------|------|
| Errors, exceptions, LUW/COMMIT, locks, update task, logging | `errors.md`, `luw.md`, `logging.md` |
| Money and counters, dates and times, strings and texts | `numbers.md`, `datetime.md`, `strings.md` |
| Types, variables, references, structures | `data.md` |
| Tables, database access, table keys | `itab.md`, `open-sql.md`, `ldb.md`, `ddic.md` |
| HR: PA master data, PD/OM, payroll | `hr-pa.md`, `hr-pa-write.md`, `hr-pa-write-dispatch.md`, `hr-pd.md`, `hr-pd-msg-buffer.md`, `hr-pd-write.md`, `hr-payroll.md` |
| Classes, signatures, method design, tests | `classes.md`, `signatures.md`, `testing.md` |
| Language, names, conditions, formatting | `style.md`, `naming.md`, `booleans.md` |
| Security and authorization | `security.md` |
| Output: ALV, classic screens | `alv.md`, `dynpro.md` |
| Files, integration, parallel, dynamic code, CDS/OData | `files-io.md`, `integration.md`, `parallel.md`, `dynamic-rtti.md`, `cds-amdp.md`, `odata.md`, `odata-v4.md` |

## Out of scope
No rule covers these topics — do not improvise: say what is missing and verify against SAP documentation ("Finding sources"): output forms (Smart Forms, SAPscript, Adobe Forms), IDoc/ALE (partner profiles, `IDOC_INBOUND_*`, HRMD_A), classic user exits (CMOD/SMOD — a BAdI **is** covered in `integration.md`), Web Dynpro, Fiori/SAPUI5, BW/analytics.

## Editing this skill
`SKILL.md` is always in context; the rules live in `reference/*.md`. Before editing, read `MAINTENANCE.md` (the invariants). The checker is not shipped with the skill: when you have it, run its checks after an edit (slugs, pointers, reference map, near-duplicates) plus the self-test that proves each check still fires; without it, verify those invariants by hand.
