# Strings and texts

> String processing and translatable text — text tables, long texts, constants, fixed-value texts.
> Related: `data.md` (types and variables), `ddic.md` (domains and data elements), `numbers.md` (conversions of values).

## Texts and translation

- **[P2]** Translatable text — a separate **text table** (`*T`) with a foreign key to the base table, not text columns in the main table. A text table supports SE63 translation, offers several lengths (short/medium/long) for one object and adds a value list / maintenance-view text column automatically. UI texts — a message class or `TEXT-` symbols, not literals (see `errors.md`).

- **[P3]** One original language for all objects of a project (e.g. English) — easier maintenance and translation; the phrase lengths differ across languages, leave space for them in the UI.

- **[P3]** Do not show system fields in the UI (`sy-uzeit`, `sy-datum`, `sy-host`, `sy-sysid`, `sy-dbsys`, …) — technical values; only business data reaches the user.

- **[P2]** Avoid creating constants for text strings: do not wrap human-readable text in `CONSTANTS` (`CONSTANTS BEGIN OF c_msg ... VALUE 'Text'`) — pass the literal directly in the popup/dialog/message call, following the project's convention for those calls. Text that must be translatable belongs in a text symbol (`TEXT-xxx`), a message class or OTR (see `errors.md`), not in a `CONSTANTS` declaration. A constant for a technical value with semantics (file extension, suffix, status code, key) is not a text string and stays allowed.

- **[P3]** Long texts (SAPscript/SO10) — via `READ_TEXT` (`id`/`language`/`name`/`object` → `TABLES lines`) and `SAVE_TEXT`/`INIT_TEXT`/`CREATE_TEXT`; do not read/store raw text tables by hand.

- **[P2]** Reading long texts per key in a loop is the N+1 read — every `READ_TEXT` decompresses the cluster of one text, and the fix that always applies is to hoist the read out of the inner loop (collect the keys, read once). A batch reader exists and is the better answer — `READ_TEXT_TABLE`, one call for a set of keys; its signature is not in the public documentation, so confirm the parameters in SE37 on the system before you use it. What stays forbidden either way is the community workaround (a direct `SELECT` from `STXH`/`STXL` plus `IMPORT tline = ... FROM INTERNAL TABLE`) — hand-reading the text clusters is the rule above.

## Strings

- **[P0]** A slice `dobj+off(len)` (and `substring( val = … off = … len = … )`) raises `CX_SY_RANGE_OUT_OF_BOUNDS` (dump `STRING_OFFSET_TOO_LARGE`) if `[off, off+len)` is not entirely inside the string: empty/short string, `off` past the end. Empty and short strings are supported values, so an unchecked slice on that path can dump. True for both `string` and `c` (for `c`, additionally `len = 0` is invalid); "return an empty string" only comes from an explicit `len = 0` for `string`, not from cutting at the boundary. Fix: `IF strlen( lv_s ) >= off + len` before the slice, or `CATCH cx_sy_range_out_of_bounds`; a slice from the edge — `left`/`right` (they cut at the boundary). If the invalid range can arise only from invalid input or an out-of-contract call, classify that specific finding as P1. <!-- rule: slice-offset-out-of-bounds -->

- **[P1]** `find( )` not found → `-1` (not `0`, not an exception); `occ = -1` — the last occurrence from the end; `occ = 0` — invalid (`CX_SY_STRG_PAR_VAL`). <!-- rule: find-returns-minus1 -->

- **[P1]** `replace( )`: `occ = 0` — replace ALL occurrences, default (`occ = 1`) — only the first. Without `sub`/`pcre` (only `off`/`len`) — replace a span by position; insert without replace — `insert( val = ... sub = ... off = ... )`. <!-- rule: replace-occ-semantics -->

- **[P2]** Stripping/padding leading zeros in NUMC keys (`PERNR`, `MATNR`, …) — `|{ x ALPHA = OUT }|`/`CONVERSION_EXIT_ALPHA_OUTPUT` (strip) and `|{ x ALPHA = IN }|`/`CONVERSION_EXIT_ALPHA_INPUT` (pad), not `SHIFT ... LEFT DELETING LEADING '0'` (fragile: does not distinguish "all zeros" from an empty string, breaks symmetry with reverse ALPHA input).

- **[P1]** `strlen( )` counts trailing spaces only in `string`: `strlen( 'abc   ' ) = 3` (`c` literal, fixed length), `strlen( \`abc   \` ) = 6` (`string` literal). `numofchar( )` counts characters except **trailing** blanks (leading/internal spaces count — `numofchar( \`  a b\` ) = 5`). <!-- rule: strlen-vs-numofchar -->

- **[P1]** A character-like comparison first adjusts the two operands to one length, and the direction depends on the types: two `c` of different length — the **shorter** is padded with blanks on the right; two `n` — the shorter is padded with `0` on the left; a `d` or `t` against `c`/`n` (`d` also against `string`) — the **longer** operand is truncated on the right to the length of the shorter; `string` against `string`, and `string` against `t`, are **not** adjusted at all. Two consequences, both directions: (1) a date or time field compared with a short character literal is valid and works — `begda = '2024'` and `sy-datum(4) = '2026'` test the year, not a defect (the documented pair `CONV t( '120000' ) = '12'` is true, `CONV t( '123000' ) <> '12'` is true); (2) where one side is `string` and the lengths differ, the operands never match and trailing blanks count — `lv_str = 'ABC '` is false for a `string` holding `ABC`, and a `string` against a `t` is false whenever the lengths differ: a condition that silently never fires. <!-- rule: char-compare-length-adjust -->

- **[P3]** Control characters — from `cl_abap_char_utilities` (`cr_lf`, `newline`, `horizontal_tab`, `backspace`, `form_feed`, `charsize`), not hand-assembled literals.
