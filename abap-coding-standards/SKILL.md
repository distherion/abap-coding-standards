---
name: abap-coding-standards
description: Rules for writing and reviewing ABAP 7.50 (SAP) code — coding standards, Clean ABAP, error handling, LUW/COMMIT, AUTHORITY-CHECK, DDIC, internal tables, Open SQL, CDS/AMDP, HR infotypes (PA/OM/PD), BAPI/RFC. Apply when editing .abap files or abapGit exports; when reviewing, auditing or refactoring a diff, class, method, function module, report, BAdI or enhancement; when fixing a short dump (ST22) or an ATC/abaplint finding; and when the user mentions ABAP, SAP, SE80/ADT, abapGit, or asks in Russian — "отревью", "правь метод", "отчёт ABAP", "инфотип". Targets NetWeaver 7.50 — no post-7.50 statements or types. Not for the SAP frontend (Fiori/SAPUI5, Web Dynpro), output forms (Smart Forms/Adobe), IDoc/ALE, BW/analytics, or ABAP Cloud.
compatibility: Target SAP NetWeaver 7.50 (ABAP). No runtime dependencies, no network access needed.
metadata:
  lang: en
---

# ABAP — rules and constraints

> Skill `abap-coding-standards` (ABAP 7.50), extended with Clean ABAP rules (SAP styleguides).
> A statement true only from a release later than 7.50 is marked inline `(7.5x+)` (e.g. `(7.54+)`; the target release itself — `(7.50)`, an older still-valid one — `(7.40+)`) and collected in `reference/style.md`, "Version: what is NOT in 7.50".
> Rules are split by topic into `reference/*.md` — open only the file for the current topic (see "Reference map").

## Review vs own code
- **Own code** = code you write/edit yourself (new diff, new methods) — follow all rules strictly.
- **Others' code** = existing legacy / review without edits — a factual error or a wrong result is a finding at its **usual severity**; only purely stylistic rules (`SELECT *`, `WITH DEFAULT KEY`, case/formatting/pretty-printer) are relaxed to P3. The author of the code does not change the fact of a defect.
- Unclear whose it is — ask, do not decide blindly.
- **Project convention wins over this skill** where the project has one: an in-house wrapper, a deliberate older form, a documented standard of the repo, an agreed exception (e.g. `itab.md` — "our project convention is to prefer `ASSIGNING`"). Follow the project and name the rule you are departing from — the rules here are defaults, not an override. This never covers a defect: a wrong result, a lost write or a bypassed authorization stays a finding whatever the convention says.

## Refactoring legacy
- **[behavior]** Boy scout rule: touch a piece of code — leave it cleaner than you found it (a small rule-compliant fix, not a large rewrite).
- **[behavior]** Clean islands: new/rewritten code — clean; do not rewrite the surrounding legacy at the same time, change only what the task touches.
- **[behavior]** Do not mix styles in one object: new code in a legacy object follows the new rules, but the whole object is not migrated at once.
- **[behavior]** Touching someone else's or shared code with a refactor — agree with the team first.

## Priorities — severity levels on review
Assign each finding to one level and report in order P0 → P3.

- **P0 — Blocker**: dump, data corruption, injection / authorization bypass. Do not merge until fixed.
- **P1 — Critical**: wrong result (races, lost/corrupted money, wrong write, unhandled error). Must fix.
- **P2 — Substantial**: slow (`SELECT` in loop, O(n²)), fragile, hard to test. Worth fixing — can be a separate task.
- **P3 — Minor**: style (naming, case, formatting, readability); others' code — per "Review vs own code". Mention in passing or skip.
- **Downgraded priority (P2 → P3 — mention in passing; never below P2 without explicit context):** two cases only, both owned by `errors.md` (`[P2]` — "Write under a lock", "COMMIT in chunks"): a write without `ENQUEUE/DEQUEUE` where concurrency is provably impossible (single-user dialog/report — an unobserved race is not proof), and `COMMIT` in chunks in deliberate mass loading where each chunk is self-consistent.
- **Exception to downgrade — broken LUW (P1):** one money/data operation split into independent `COMMIT`s, so an interruption leaves a half-saved state — a payment without its items, a header without its rows, an error swallowed while `COMMIT` still runs. A defect, not "COMMIT in a loop".

**Markers** at the start of a rule: `[P#]` — severity on review; `[info]` — background knowledge (syntax, platform, name limits), not a finding — do not report, but its claims still need the same verification as any other reference ("Finding sources"); `[behavior]` — an instruction to the agent (how to search, when to ask, what to edit), not a code finding. Own code — follow all rules regardless of the marker. Inside a rule, the lead-in `**does not exist:**` marks a claim that an API, parameter or statement does **not** exist — a class of its own, verified like any other claim and the one that keeps an invented API out of the code (`MAINTENANCE.md`).

**Citing a rule in a review report:** P0/P1 rules carry a stable slug in a trailing HTML comment (the literal `rule:` followed by the slug, invisible in render) — a machine-searchable identifier, **not** an anchor: an HTML comment creates no link target, so cite rules **point-in-time as `file.md:line`** (e.g. `errors.md:19`) and name the `rule:`-slug in parentheses. Slugs are unique per file and survive reordering; P2/P3/`[info]` have no slug — cite them as `file.md:line`. P0/P1 without explicit context are never silently downgraded to P3 (legitimate cases — "Priorities" above).

## Review flow
1. Verify references and logic — per "Context — don't invent" and "Logic above rules".
2. Run the checklist by topic (open the relevant `reference/*.md`), assign each finding a level P0–P3.
3. Report in order P0 → P3; P3 — in passing or skip.

## Review report
The report is a document somebody acts on, so it has a fixed shape: findings first in severity order, then what was covered and what was not.

- **[behavior]** One finding — one line: **`<severity> <file>:<line> (<rule:slug>) — what breaks (concrete scenario: input/state → wrong result) — fix`**. P0/P1 — always with the scenario; P2/P3 — the defect and the fix, no scenario needed.
- **[behavior]** Quote the shortest decisive fragment of the code, not a paraphrase of the rule; no praise, no restating a rule that is not violated. No concrete fix — not a finding, but a remark: keep it out of the report or mark it as a question.
- **[behavior]** Close with two lines: `Checked: <files and areas>` and `Not checked: <what was left out and why>`. No local syntax check is available (activation happens in SAP) — that belongs under "Not checked". No findings — say it explicitly with the same two lines, do not return an empty report: a review that does not say where it stopped reads as a review of everything.

## Logic above rules
Always look for logic errors and potential problems — even those not in the rules. The rules are a minimal checklist, not an exhaustive list. Beyond them check: races and wrong call order, lost/stuck states, edge cases (empty inputs, short strings, invalid dates, missing records), silent failures, double/extra side effects, mismatch between caller and callee, unset flags/statuses. Assign any finding a level P0–P3 and give a concrete fix.

## Finding sources
- **[behavior]** In doubt about an API, standard SAP behavior, the semantics of an FM/class/infotype, syntax or ABAP limits — first look in official documentation and internal sources (guides/notes/Confluence), with network access — SAP Help Portal / ABAPDocu / SAP Notes, then Stack Overflow / SAP Community. Do not invent and do not ask blindly.

## Context — don't invent
- **[behavior]** Do not invent DDIC structures/tables/interfaces/classes/FMs, fields and signatures. No definition or not enough context (inheritance hierarchy, BAdI points) — **ask a clarifying question** before writing code.
- **[behavior]** Verify actual method/component names against the code, not by assumption.
- **[behavior]** **On review, verify every reference against its definition in the repo, do not trust what is written**: `MESSAGE eNNN(class)` ↔ `.msag.xml` (number exists, `&1..&4` matches `WITH`); class/interface/FM/method names ↔ declaration (`.clas.abap`/`.intf.abap`/`.fugr.*`/`.prog.*`); fields/components ↔ `TYPES`/`.tabl.xml`; call signature ↔ method declaration. A mismatch is a P0–P2 finding; no definition in the repo — "context missing, verify", do not assume.

## Automated checks
- **[behavior]** Run static analyzers as part of the review — they catch their defined set (naming, syntax, anti-patterns); logic, races, LUW and the rest still need the manual pass. In-system — ATC (Code Inspector); on abapGit code — abaplint (`abaplint.json`), code pal for ABAP, abapOpenChecks, SonarSource ABAP (CI without an ABAP system).
- **[behavior]** Before writing your own utility, check the open-source ecosystem — it probably exists.

## Local editing of `.abap` files

- **[behavior]** Files are an abapGit export: UTF-8 + LF, Cyrillic written directly (no `\u04XX`-escapes); legacy cp1251+CRLF files — rewrite entirely via Write.
- **[behavior]** Edit `.abap` files with your own file-editing tools (read/edit/write) — never through shell text utilities (`iconv`/`sed`/`awk` on unix, PowerShell/cmd on Windows) for editing or converting. Local syntax check is unavailable — activation happens in SAP; say so in the output.
- **[behavior]** After edits, check the block balance: `METHOD/ENDMETHOD`, `TRY/ENDTRY`, `IF/ENDIF`, `LOOP/ENDLOOP`, `CASE/ENDCASE`, `DO/ENDDO`.
- **[P3]** SE24 adds a `* <SIGNATURE>` method header; an abapGit export has none — do not expect or remove it.

## Reference map
Open only the file for the topic at hand:

| When the task touches… | Open |
|------------------------|------|
| Errors, exceptions, LUW/COMMIT, locks, update task, logging | `errors.md`, `logging.md` |
| Money and counters, dates and times, strings and texts | `numbers.md`, `datetime.md`, `strings.md` |
| Types, variables, references, structures | `data.md` |
| Tables, database access, table keys | `itab.md`, `open-sql.md`, `ldb.md`, `ddic.md` |
| HR: PA master data, PD/OM, payroll | `hr-pa.md`, `hr-pa-write.md`, `hr-pd.md`, `hr-pd-write.md`, `hr-payroll.md` |
| Classes, method design, unit tests | `classes.md`, `testing.md` |
| Language, names, conditions, formatting | `style.md`, `naming.md`, `booleans.md` |
| Security and authorization | `security.md` |
| Output: ALV, classic screens | `alv.md`, `dynpro.md` |
| Files, integration, parallel, dynamic code, CDS/OData | `files-io.md`, `integration.md`, `parallel.md`, `dynamic-rtti.md`, `cds-amdp.md`, `odata.md`, `odata-v4.md` |

## Out of scope
There is no rule for these topics — do not improvise from the rulebook, say what is missing and verify against SAP documentation (see "Finding sources"): output forms (Smart Forms, SAPscript, Adobe Forms), IDoc/ALE (partner profiles, `IDOC_INBOUND_*`, HRMD_A), classic user exits (CMOD/SMOD — BAdI **is** covered in `integration.md`), Web Dynpro, Fiori/SAPUI5 frontend, BW/analytics.

## Editing this skill
`SKILL.md` is always in context; the rules live in `reference/*.md`. Before editing: read `MAINTENANCE.md` (the invariants). A checker lives next to the skill in the repo that hosts it (not shipped with the skill): run it after an edit (slugs, pointers, the reference map, near-duplicates) and its self-test, which proves each of those checks still fires.
