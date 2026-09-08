---
name: abap-coding-standards
description: Rules for writing and reviewing ABAP 7.50 (SAP) code. Apply when editing .abap files, ABAP code, DDIC, infotypes, OData services, or when the user mentions ABAP/SAP. A dense checklist of coding standards, Open SQL, LUW and working with local files.
lang: en
---

# ABAP — rules and constraints

> Skill `abap-coding-standards` (ABAP 7.50). Extended with Clean ABAP rules (SAP styleguides).
> Rules are split by topic into `reference/*.md`. Open only the file for the current topic
> (see "Reference map"), do not load the whole reference at once.

## Review vs own code
- **Own code** = code you write/edit yourself (new diff, new methods) — follow all rules strictly.
- **Others' code** = existing legacy / review without edits — a factual error or a wrong result is a finding at its **usual severity**; only purely stylistic rules (`SELECT *`, `WITH DEFAULT KEY`, case/formatting/pretty-printer) are relaxed to P3. The author of the code does not change the fact of a defect.
- Unclear whose it is — ask, do not decide blindly.

## Refactoring legacy
- **[behavior]** Boy scout rule: touch a piece of code — leave it cleaner than you found it (a small rule-compliant fix, not a large rewrite).
- **[behavior]** Clean islands: new/rewritten code — clean; do not rewrite the surrounding legacy at the same time, change only what the task touches.
- **[behavior]** Do not mix styles in one object: do not leave a class half on old `FORM`/non-RFC `FM`, half on methods. New code in a legacy object — by the new rules, but without migrating the whole object at once.
- **[behavior]** A refactor touches someone else's/shared code — agree with the team, do not rewrite unilaterally.

## Priorities — severity levels on review
Assign each finding to one level and report in order P0 → P3.

- **P0 — Blocker**: dump, data corruption, injection / authorization bypass. Do not merge until fixed.
- **P1 — Critical**: wrong result (races, lost/corrupted money, wrong write, unhandled error). Must fix.
- **P2 — Substantial**: slow (`SELECT` in loop, O(n²)), fragile, hard to test. Worth fixing — can be a separate task.
- **P3 — Minor**: style (naming, case, formatting, readability); others' code — per "Review vs own code". Mention in passing or skip.
- **Downgraded priority — P3 (mention in passing, do not raise to P1/P0 without explicit context):** writes without `ENQUEUE/DEQUEUE` — only when concurrent access is provably impossible in the scenario (single-user dialog/report); the absence of an **observed** race is not proof of safety — with any real concurrency a lock-free write stays P1/P2. `COMMIT` in chunks — only in deliberate mass loading where each chunk is self-consistent and an interruption between chunks loses no money/data.
- **Exception to downgrade — broken LUW (P1):** one logical money/data operation split into independent `COMMIT`s so that an interruption/failure leaves a half-saved state — a payment "deleted" while REGUH rows stay active; headers committed without line items; `CATCH` swallows the error while `COMMIT` still runs. This is not "COMMIT in a loop", it is a broken LUW — P1, must fix. (COMMIT/LUW rules — in `errors.md`.)

**Markers** at the start of a rule: `[P#]` — severity on review; `[info]` — background knowledge (syntax, platform, name limits), not a finding — do not report, but its claims still need the same verification as any other reference ("Finding sources"); `[behavior]` — an instruction to the agent (how to search, when to ask, what to edit), not a code finding. Own code — follow all rules regardless of the marker.

## Review flow
1. Verify every reference against its definition in the repo — see "Context — don't invent".
2. Look for logic errors/races/edge cases beyond the checklist (see "Logic above rules").
3. Run the checklist by topic (open the relevant `reference/*.md`), assign each finding a level P0–P3.
4. Report in order P0 → P3; P3 — in passing or skip.

## Logic above rules
Always look for logic errors and potential problems — even those not in the rules. The rules are a minimal checklist, not an exhaustive list. Beyond them check: races and wrong call order, lost/stuck states, edge cases (empty inputs, short strings, invalid dates, missing records), silent failures, double/extra side effects, mismatch between caller and callee, unset flags/statuses. Assign any finding a level P0–P3 and give a concrete fix.

## Finding sources
- **[behavior]** In doubt about an API, standard SAP behavior, the semantics of an FM/class/infotype, syntax or ABAP limits — first look in official documentation and internal sources (guides/notes/Confluence), with network access — SAP Help Portal / ABAPDocu / SAP Notes, then Stack Overflow / SAP Community. Do not invent and do not ask blindly.

## Context — don't invent
- **[behavior]** Do not invent DDIC structures/tables/interfaces/classes/FMs, fields and signatures. No definition or not enough context (inheritance hierarchy, BAdI points) — **ask a clarifying question** before writing code.
- **[behavior]** Verify actual method/component names against the code, not by assumption.
- **[behavior]** **On review, verify every reference against its definition in the repo, do not trust what is written**: `MESSAGE eNNN(class)` ↔ `.msag.xml` (number exists, `&1..&4` matches `WITH`); class/interface/FM/method names ↔ declaration (`.clas.abap`/`.intf.abap`/`.fugr.*`/`.prog.*`); fields/components ↔ `TYPES`/`.tabl.xml`; call signature ↔ method declaration. A mismatch is a P0–P2 finding; no definition in the repo — "context missing, verify", do not assume.
- **[behavior]** Unsure about an API or standard SAP behavior — see "Finding sources".

## Automated checks
- **[info]** Run static analyzers as part of the review: they reliably catch their defined check set (naming, syntax, common anti-patterns). Manual review is additionally required for logic, races, LUW and defects the analyzers do not check.
- **[behavior]** Before writing your own utility/library, check the ABAP open-source ecosystem — a ready one probably already exists.

## Reference map
Open only the file relevant to the task topic:

| File | Topic |
|------|------|
| `reference/errors.md` | Error handling, exceptions, LUW/ENQUEUE/COMMIT, update task, resumable |
| `reference/logging.md` | Logging (`cl_reca_message_list`, Application Log) |
| `reference/data.md` | Types and DDIC, numbers, date/time, variables and internal tables, strings |
| `reference/open-sql.md` | Open SQL, performance, buffer, client, JOIN |
| `reference/security.md` | Security, dynamic SQL, authorization, HR infotypes |
| `reference/classes.md` | Classes, signatures and method calls, method body, DI |
| `reference/testing.md` | Unit testing (ABAP Unit): principles, test classes, double injection, test methods, data, assertions |
| `reference/parallel.md` | Parallelism, bgRFC/aRFC, background jobs |
| `reference/cds-amdp.md` | CDS Views, AMDP (SQLScript) |
| `reference/dynamic-rtti.md` | Dynamic programming, RTTI/RTTS |
| `reference/style.md` | Language and style, names, booleans, built-ins, version (not 7.50), formatting |
| `reference/odata.md` | OData (SEGW / Gateway) |
| `reference/files-io.md` | File I/O in ABAP (DATASET, gui_upload/download, encodings, JSON/XML) |
| `reference/integration.md` | Integration: batch input (BDC), memory (ABAP/SAP/Shared), BAdI |
| `reference/local-editing.md` | Local editing of `.abap` files (encoding, block balance) |
