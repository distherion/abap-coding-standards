# Language and style

- **[P3]** ABAP 7.50, unless stated otherwise.
- **[P3]** **Line length < 120 characters** — wrap long expressions.
- **[P3]** Functional constructs: `DATA(...)`, `VALUE #()`, `CORRESPONDING #()`, `NEW`, `COND`, `SWITCH`, `REDUCE`.
- **[P3]** **No mixing of equivalent spellings** — pick one alternative per construct and use it consistently (comparison operators `=`/`<>` vs `EQ`/`NE`; modern vs legacy statement variants, see the next bullet).
- **[P3]** **No obsolete statements** — where 7.50 has a modern replacement, use it (ABAPDocu "Obsolete Language Elements", Clean ABAP). Concrete replacements — in this section (`MOVE` → `=`, `CREATE OBJECT` → `NEW`), in `data.md` (`REFRESH` → `CLEAR`, `MOVE-CORRESPONDING`, `TABLES`/`NODES`/`WITH HEADER LINE`) and `open-sql.md` (unescaped host variables).
- **[P3]** **Strings/operators**: templates `|...|` and `&&` instead of `CONCATENATE`/`STRING`; `MOVE` → `=`, `TRANSLATE` → `to_upper`/`to_lower`, `CONDENSE` → `condense( )`; `#EC` → pragmas `##` where the check has one (`##NO_TEXT`, `##INCLUDED`, …); keep the legacy `#EC CI_*` pseudo-comment for cross-statement checks that still have no `##` equivalent in 7.50. A `##`-pragma goes to the end of the affected statement (before the period/comma) — when the code changes, reposition it rather than deleting or leaving it orphaned.
- **[P3]** String literals — backtick `` `...` `` (type `string`) instead of `'...'` (type `c`, fixed): no redundant CHAR↔STRING conversion and no doubt about the exact type (note `strlen( 'abc   ' ) ≠ strlen( \`abc   \` )`, see `data.md`).
- **[P3]** There is no `ENUM` in ABAP 7.50. Instead of an enum — constants in an `INTERFACE` (`zif_xxx=>c_value`), used directly, without `INTERFACES zif_xxx` in the class; do not use an enumeration class (a class with `CONSTANTS`) when an interface suffices.
- **[P3]** Regular expressions — only when simple checks are not enough. Prefer `find`, `CS`/`NS`, `CO`/`CN`, `CA`/`NA`; when a regex is needed — `regex` (POSIX; the `pcre` dialect appeared only in **7.55**, NOT in 7.50); build a complex regex from named constants, not a raw literal. Do not compile a regex per call/in a loop — precompile once (`cl_abap_regex`) and reuse; for validation-style match/no-match the dominant idiom is `cl_abap_matcher=>matches( pattern = ... text = ... )` — use it over the raw `regex` built-in; avoid catastrophic backtracking (nested quantifiers like `(a+)+` — a ReDoS on long input); anchor with `^`/`$` when a full match is intended.
- **[P3]** Constants instead of magic numbers; group constants in `BEGIN OF … END OF` blocks. Name a constant by its **meaning**, not by the literal it holds: `lc_storage_class` for `'C123'`, not `lc_c123` — renaming a value into a same-named literal adds no information (Clean ABAP: "constants also need descriptive names").
- **[P3]** Comments via `"`, not `*`. Comment the "why", not the "what". No commented-out code and no auto-signatures.
- **[P2]** **Comments only in English.** Russian in comments is forbidden (Cyrillic is allowed only in string literals, e.g. `|Мужской|`).
- **[P3]** Do not add manual versioning (`" ticket ABC ++ Start/End` around a piece): the version control system tracks versions, the reason — in the transport text. `TODO`/`FIXME`/`XXX` — only with initials.
- **[P3]** Comment before the statement it relates to; no end-of-block comments (`ENDIF. " END OF IF` — the block structure says it). ABAP Doc — only for public APIs, not for internal methods/attributes; when a public method is documented — document all its parameters and `RAISING` exceptions (one line each), no partial documentation.

# Names

- **[P3]** `snake_case` everywhere (ABAP is case-insensitive).
- **[P3]** No noise words (`data`, `info`, `object`, `controller`).
- **[P3]** No unnecessary abbreviations; one abbreviation — one meaning everywhere.
- **[P3]** Classes — nouns, methods — verbs.
- **[P3]** Collections — plural (`lt_employees`, not `lt_employee`).
- **[P3]** One word — one concept (not `get`/`read`/`fetch` for one action).
- **[P3]** Prefixes — SAP convention, we keep them (a deliberate rejection of Clean ABAP's "no prefixes"): parameters `iv_`/`is_`/`it_`/`ir_` (import), `ev_`/`es_`/`et_`/`er_` (export), `cv_`/`cs_`/`ct_` (changing), `rv_`/`rs_`/`rt_` (returning); locals `lv_`/`ls_`/`lt_`/`lo_`/`lr_`/`lf_`; attributes `mv_`/`ms_`/`mt_`/`mo_`/`mr_`.
- **[P3]** Development object names — only in English (`abap-best-practice`, Clean ABAP); search in the solution domain (computer-science terms: queue, tree) and the problem domain (business terms: account, ledger); names must be pronounceable; names of design patterns — only when the pattern is really implemented (`file_factory` only if it is a factory).
- **[info]** **Name limits** (SAP constraints): DB table (transparent table, DDIC) — 16; view — 16 (letters, digits, underscores, must start with a letter); local internal table — 30; global class/interface — 30; program (report/include) — 30 (40 only for internal SAP tool names with 5-char suffixes); FM — 30; function group — 26 (generates `SAPL<fg>`/`L<fg>TOP`); message class — 20; package — 30 (`Z`/`Y` or namespace); domain / data element / structure / table type / search help — 30; field/component — 30 (up to BASIS 7.02 — 16); lock object — 16 (name with `E`, generates `ENQUEUE_`/`DEQUEUE_`). The namespace prefix `/xxx/` counts toward the limit.
- **[P2]** New objects — only `Z`/`Y` or namespace `/xxx/`; do not create in the SAP range (`A`–`X`) — conflict on upgrade/import of packages.
- **[P1]** Do not name methods/classes after built-in functions (`lines`, `strlen`, `line_exists`, `to_upper`, `condense`, `substring`) — a call inside the class would go to your method, not the built-in function. (Note: `value`/`cond`/`switch` are **not** reserved — they can be names, only the readability/semantics matters.) <!-- rule: no-builtin-method-names -->

# Booleans and conditions

- **[P3]** `abap_true`/`abap_false` instead of the literal `'X'`/`' '`. Check an `abap_bool` via the constants — `= abap_true`/`= abap_false`, not `IS INITIAL`/`IS NOT INITIAL` or a space comparison: `IS INITIAL` reflects technical emptiness of the data object, the constant — the semantic value (and the pair `abap_true`/`abap_false` is the single project-wide definition).
- **[P1]** Booleans from conditions — `xsdbool( )`: returns `c(1)`, compare with `abap_true`/`abap_false`. `boolc( )` returns `string` (`X`/space) — do not compare with `abap_true`/`abap_false` (the `c`↔`string` conversion gives a wrong result). `boolx( bool = ... bit = ... )` — a bit by number. <!-- rule: booleans-xsdbool-boolc -->
- **[P3]** Positive conditions (`IS NOT` instead of `NOT IS`); `CASE` instead of `ELSE IF`.
- **[P3]** Complex conditions (`IF a AND b AND c`) — extract into a predicate method `is_...` with a telling name.
- **[P3]** Predicative call of a boolean method: `IF is_valid( ).` / `IF NOT can_archive( ).` — the condition reads like a phrase; a method called in a condition must be free of side effects (called for its result, not its effect).
- **[info]** ABAP evaluates `AND`/`OR` from left to right with **short-circuit**: once the result is determined by the left side, the right side is not evaluated (ABAPDocu "Logical expressions"). The documentation recommends placing the cheap/usually-false comparison first in an `AND` chain.
- **[info]** `WHEN OTHERS` in `CASE` — only last: it must be the final branch (a `WHEN` after it is a syntax error). `WHEN OTHERS` is checked by the syntax check, so "shadowing the following `WHEN`" cannot happen in compiling code — do not flag it as an error or a shadowing defect.

# Built-in functions

- **[info]** String (7.40+): `find`, `find_end`, `find_any_of`, `find_any_not_of`, `count`, `count_any_of`, `count_any_not_of`, `contains`, `contains_any_of`, `contains_any_not_of`, `substring`, `substring_after`, `substring_before`, `substring_from`, `substring_to`, `replace`, `insert`, `condense`, `segment`, `shift_left`, `shift_right`, `repeat`, `reverse`, `match`, `matches`, `distance`, `to_upper`, `to_lower`, `to_mixed`, `from_mixed`, `concat_lines_of`, `cmin`, `cmax`, `numofchar`, `strlen`, `xstrlen`, `escape`.
- **[info]** Numeric (7.40+): `abs`, `sign`, `ceil`, `floor`, `trunc`, `frac`, `round`, `rescale`, `ipow`, `nmin`, `nmax`, `sqrt`, `sin`/`cos`/`tan`, `asin`/`acos`/`atan`, `sinh`/`cosh`/`tanh`, `exp`, `log`, `log10`.
- **[info]** Predicates `contains( )`, `matches( )`, `line_exists( itab[ ... ] )` are **predicate functions** — usable in logical expressions, not functions returning a value: you cannot assign them straight to a `c(1)` variable (use `xsdbool( )`); `line_exists` does not raise `CX_SY_ITAB_LINE_NOT_FOUND`.

# Screens and events

- **[P2]** No business logic in dialog modules (`PBO`/`PAI` of a Dynpro) and event blocks (`INITIALIZATION`, `START-OF-SELECTION`, `END-OF-SELECTION`, `AT SELECTION-SCREEN...`, `AT LINE-SELECTION`, `GET`, `TOP-OF-PAGE`): the module/event reads the screen/selection state and delegates to a class method. Business rules in a class are testable and do not depend on the UI; a dialog module must not compute or write direct. (Screen flow logic — `CHAIN`/`FIELD`/`AT EXIT-COMMAND`/`LOOP AT SCREEN` — see `dynpro.md`.)
- **[P3]** Selection screens / PAI: labels — from text elements, not literals; defaults — set and reset in `INITIALIZATION`; validation — in `AT SELECTION-SCREEN`/PAI with `MESSAGE TYPE 'E'` before the action proceeds; cross-field checks — a class method, not inline in the module.
- **[P3]** Accessibility of the UI: do not convey information by color alone (color-blind users); icons — a tooltip; table columns — a header; input/output fields — a meaningful label; fields grouped into frames with a meaningful title. Verified device-independent behavior helps people with impairments and is a compliance factor.

# Version: what is NOT in 7.50

The skill targets ABAP 7.50. These features look like 7.40/7.50 but are unavailable — do not propose them in 7.50 code:
- `SELECT ... FROM @itab AS alias` (internal table as an ABAP SQL source) — from 7.52; pragma `##itab_db_select` — from 7.53.
- Type `utclong`, functions `utclong_current`/`utclong_add`/`utclong_diff`, `CONVERT UTCLONG`, `cl_abap_utclong` — from 7.54.
- DDIC types `DATN`/`TIMN`/`UTCLONG` — from 7.54 (in 7.50 — `dats`/`tims`/`timestamp`/`timestampl`).
- Computed assignments `+=`, `-=`, `*=`, `/=`, `&&=` — from 7.54.
- XCO (`xco_cp=>...`) — not available in NetWeaver 7.50 (it ships with ABAP Cloud and on-premise ABAP Platform 2021+/S/4HANA 2021+); in a 7.50 target do not propose it.

# Formatting

- **[P3]** One statement per line.
- **[P2]** No chained operational statements (`CATCH:`, `WHEN:`, `SELECT`/`UPDATE` chains): each chain element is a separate statement — `CATCH: cx_a, cx_b, cx_c.` is `CATCH cx_a. CATCH cx_b. CATCH cx_c.` and only the last block gets the handler code (the first two catch nothing); `UPDATE scustom SET: f1 = ..., f2 = ... WHERE id = ...` is two `UPDATE`s — the first without a `WHERE` changes all rows. Write one statement per line; exceptions into one block — `CATCH cx_a cx_b cx_c.` (ABAPDocu "Chained Statements").
- **[P3]** No chains in up-front declarations (`DATA:`/`TYPES:`/`CONSTANTS:`/`FIELD-SYMBOLS:`): one declaration per statement; a chain is allowed only for deliberately related declarations and for `TYPES: BEGIN OF … END OF` (Clean ABAP: "Do not chain up-front declarations").
- **[P3]** No chained assignments `a = b = c` — in ABAP this is a **multiple assignment** (the value of `c` is assigned to both `b` and `a`), not a comparison and not an associative chain in the C sense; an inline declaration `DATA(...)` cannot be the destination of a chain. Write separate statements — a chain hides the data flow.
- **[P3]** Compress: remove extra blank lines, extra assignments.
- **[P3]** One blank line to separate logical blocks **inside a method**. Between top-level elements of a class the formatter puts 2–3 blank lines (`ENDMETHOD` → `METHOD`, end of `DEFINITION` → `IMPLEMENTATION`) — that is normal, do not compress to one.
- **[P3]** Close brackets at the end of the line.
- **[P3]** **Wrap a call chain (`->`) by `)->`**: the closing bracket of the current call and the arrow of the next — together, do not leave `)` at the end of a line separate from `->`.
- **[P3]** **Case**: keywords — UPPER, everything else (identifiers, type/method/parameter names, fields, built-in functions `lines`/`to_upper`/`xsdbool`) — LOWER. The pretty-printer **can** change the case of identifiers (depends on its setup) — write lower immediately; legacy-upper (`CLASS ZCL_X IMPLEMENTATION.`) — do not flag.
- **[P3]** **Punctuation**: no space before a comma and period (`TYPE datum.`, not `TYPE datum .`).
- **[P3]** **Indentation**: spaces, +2/level; `METHOD`/`ENDMETHOD` — column 0, no leading spaces; no tabs. Write by convention immediately — the diff to abapGit code is clean, do not fight the formatter.
- **[P3]** **Team formatter settings**: use the team's pretty-printer settings, do not bring your own; do not mass-reformat other people's code — a reformatting diff hides the actual change and blocks the review.
- **[info]** The `!`-escape before a parameter name in `METHODS`/`INTERFACES` — placed by the ABAP pretty printer (case protection); do not add by hand, it is normal in exports.
- **[P3]** **SELECT formatting**: fields from `SELECT`/`WHERE`/`JOIN` — each on its own line, field names one under another (aligned into a column). `ON` — on its own line at the level of `AND`, condition fields in the column:
  ```abap
  SELECT
    a~pernr,
    b~endda
    FROM pa0001 AS a
    INNER JOIN pa0007 AS b
      ON  b~pernr = a~pernr
      AND b~begda <= @lv_date
      AND b~endda >= @lv_date
    WHERE a~pernr = @lv_pernr
      AND a~endda = @lv_endda
    INTO @DATA(ls_wa).
  ENDSELECT.
  ```
