# Data types and DDIC

- **[P2]** Money and exact amounts — only `p` (or DDIC `CURR`/`QUAN`), never `f` (binary float): `0.815` in `f` is stored as `8.1499…E-01` and rounds to `0.81`. Never compare floats for equality.
- **[P3]** Conversions — explicit: `CONV #( )`/`CONV type( )` or string templates `|{ lv_num }|`; do not rely on implicit ones — numeric assignments silently narrow (`i` from `p` drops the fraction, overflow with no error), comparisons implicitly convert type. Watch length/decimals when moving `CURR`/`QUAN`.
- **[P2]** A `CURR`/`QUAN` field must have a reference field — a `CUKY`/`UNIT` column in the same table/structure.
- **[P3]** Do not write date arithmetic (months/years, end of month, seniority) by hand — use proven utilities: `cl_reca_date` (RE-FX) or the standard FM `RP_CALC_DATE_IN_INTERVAL` (`date`/`days`/`months`/`years`/`signum` → `calc_date`, not RE-FX-dependent; verify the exact signature in SE37). End of month — `CONV d( lv_first_day_of_next_month - 1 )` or FM `RP_LAST_DAY_OF_MONTHS`.
- **[P1]** Do not extend your own `Z`-tables/structures with append structures — that is a tool for SAP objects (your own fields there — `ZZ`/`YY`; for an SAP object look first for the Customizing Include `CI_*`); respect the enhancement category.
- **[P2]** Do not proliferate domains: flags/statuses — a domain with fixed values. Reuse standard data elements (`BUKRS`, `WAERS`, `PERNR`…) — they bring value table, search help, translations; a custom dtel only for new semantics.
- **[P2]** Generating document/record numbers — via number range (`NUMBER_GET_NEXT`), not by hand (`MAX + 1` — a race under parallelism). Gaps in numbers are normal: do not require continuity, do not "fix" holes; the buffered number comes from the range.

# Numbers

- **[P1]** Integer division `/` rounds commercially (round half up): `4 / 5 = 1`, `2 / 3 = 1`, `5 / 2 = 3`. The integer part without rounding comes from `DIV`: `4 DIV 5 = 0`, `7 DIV 3 = 2`. Do not confuse them — it gives a wrong result.
- **[P1]** `DIV`/`MOD` — non-negative remainder: `-7 DIV 3 = -3`, `-7 MOD 3 = 2` (invariant `n = (n DIV d)*d + (n MOD d)`, the sign of the remainder is the sign of the divisor).
- **[P1]** Division by zero: `x / 0` (x≠0), `x DIV 0`, `x MOD 0` → `CX_SY_ZERODIVIDE`; only `0 / 0 = 0` without exception.
- **[P1]** `**` returns type `f` (binary float, precision loss) — for an integer power use `ipow( base = ... exp = ... )`.
- **[P1]** Integer overflow (`2147483647 + 1`) → `CX_SY_ARITHMETIC_OVERFLOW` (catchable).
- **[P1]** Inline `DATA(x) = lv_packed + 1` with a `p` operand gives `p LENGTH 8 DECIMALS 0` — the fraction is lost. For fractions declare the type explicitly: `DATA(x) TYPE p LENGTH 8 DECIMALS 2`.
- **[P1]** `EXACT` on digit loss: `CX_SY_CONVERSION_ROUNDING` (fraction/digits lost), `CX_SY_CONVERSION_OVERFLOW` (overflow) — catch it or guarantee the range.
- **[info]** Rounding: `round( val = ... dec = ... [mode = ...] )`, `ceil`/`floor`/`trunc`/`frac`; `nmin`/`nmax` — min/max of arguments; `cl_abap_math` constants (`pi`, `e`, `min_*`/`max_*` for decfloat/integers).

# Date and time

- **[info]** Types `d`/`t` in arithmetic behave like `i`: `d` = days since 01.01.0001, `t` = seconds since midnight. A direct date difference gives days: `DATA(days) = lv_date2 - lv_date1.`
- **[P1]** Time difference across midnight — take `MOD 86400`, otherwise a negative result: `DATA(diff) = ( lv_time2 - lv_time1 ) MOD 86400.`
- **[info]** Day of week (1 = Monday): do not compute via `lv_date MOD 7` — ABAP's internal day counter skips 05–14.10.1582 (Julian→Gregorian), so `MOD 7` gives an offset. Compute via the difference from a known Monday (`20240101`): `DATA(wd) = ( lv_date - CONV d( '20240101' ) ) MOD 7 + 1.` (`MOD` returns a non-negative remainder — also works for dates before the reference.) Or FM `DAY_IN_WEEK`/`DATE_GET_WEEK` (verify the signature in SE37).
- **[P1]** `CONVERT TIME STAMP ... TIME ZONE ... INTO DATE ... TIME ...` sets `sy-subrc`: `8` = invalid timezone, `12` = invalid timestamp — check immediately (see `errors.md`).
- **[P1]** `EXACT d( lv_str )` validates the date — on an invalid one it raises `CX_SY_CONVERSION_NO_DATE`; `CONV d( )` does not validate.
- **[info]** Timezone: server — `sy-datum`/`sy-uzeit`; user's local — `sy-datlo`/`sy-timlo`/`sy-zonlo`; user timezone — `cl_abap_context_info=>get_user_time_zone( )`.
- **[P3]** Timestamp arithmetic — prefer `cl_abap_tstmp`, not manual recomputation of `timestampl`/`CONVERT`: difference — `cl_abap_tstmp=>subtract( tstmp1 = ... tstmp2 = ... )` (→ seconds), add — `cl_abap_tstmp=>add( tstmp = ... secs = ... )` (verify exact names/parameters in SE24). Local↔UTC — `systemtstmp_syst2utc`/`systemtstmp_utc2syst`; DST — `systemtstmp_syst2loc`/`systemtstmp_loc2syst`/`is_double_interval`. `GET TIME STAMP` returns UTC. `CONVERT TIME STAMP` only converts, does not add. In DB `SELECT` — built-ins `tstmp_add_seconds( )`/`tstmp_seconds_between( )`/`tstmp_is_valid( )` (7.50).

# Variables and internal tables

- **[info]** Inline `DATA(...)` instead of upfront blocks. **ABAP has no block scoping**: a variable declared inside `IF`/`LOOP`/`CASE`/`DO`/`TRY` (including `FIELD-SYMBOLS`) is visible to the end of the method — use below in the code is valid, do not flag it as an error.
- **[info]** One inline name (`DATA(x)`, `CATCH ... INTO data(x)`) cannot be declared twice in one method — that is a syntax error (not a review finding). Declare a variable used by several `CATCH`/loops once at method level (`DATA lx_error TYPE REF TO cx_root.`) and reuse it.
- **[P2]** Inline `DATA(x)`/`FIELD-SYMBOL` inside a branch (`IF`/`CASE`/`TRY` without `ELSE`/`CATCH`): if the branch did not run, the variable is not declared/assigned — using it below gives `x is not assigned`/garbage. Declare before the branch or fill it in all branches.
- **[P2]** Do not modify system fields (`sy-subrc`, `sy-tabix`, `sy-index`, `sy-datum`, …) — a direct write to them is not allowed. Use a local variable for your own counter/flag.
- **[P2]** Shadowed variable: a local (`lv_*`/`DATA(x)`) named like an attribute/global hides it — the wrong one is read. Do not name locals like attributes.
- **[P2]** Do not use `sy-sysid`/`sy-sysuuid`/`sy-host` in business logic (ties to system/host). Identifiers — via configuration/constants.
- **[P3]** Initialization with a named type: `DATA(lv_x) = VALUE ty_type( ).` instead of `DATA lv_x TYPE ty_type.`; anonymous types (`TABLE OF … WITH KEY`, `WITH DEFAULT KEY`) cannot be declared inline — use `TYPE` there.
- **[P3]** `INSERT INTO TABLE` — when uniqueness matters (`SORTED`/`HASHED`; a duplicate — `sy-subrc = 4`); `APPEND` — for `STANDARD` (insertion order, duplicates allowed). `line_exists()` instead of `READ TABLE … NO FIELDS`; `LOOP AT … WHERE` instead of a nested `IF`.
- **[info]** `REF #( )` instead of `GET REFERENCE OF` for data references.
- **[P3]** `MOVE-CORRESPONDING` → `CORRESPONDING #( ... )`: explicit `MAPPING`/`EXCEPT`, the contract is visible, safer when the structure changes.
- **[P3]** Constructor operators (`VALUE`, `COND`, `SWITCH`, `CORRESPONDING`, `CONV`, `NEW`, `REDUCE`, `FILTER`, `REF`) — type via `#` when it is inferred from context: a typed variable/field, a typed method parameter, a table row. Explicit type (`COND type( )`, `VALUE type( )`) — only when the context gives no type: inline `DATA(...)` with no surrounding type, a generic parameter `c`/`n`/`x`, ambiguity (`DATA(x) = COND abap_bool( ... )`, `DATA(lt) = VALUE infty_tab( ... )`).
- **[P1]** Do not delete table rows inside a loop (index shift → skips/duplicates). Collect keys and remove after the loop with one `DELETE ... WHERE key IN lt_keys`; or mark rows in the loop via a field-symbol (clear key fields) and delete `DELETE ... WHERE key IS INITIAL` — the second way only if living rows always have the key filled.
  Legal (do not flag): `DELETE lt_x.` / `DELETE … INDEX sy-tabix` of the current row inside its own `LOOP AT lt_x`.
- **[P3]** No `DEFAULT KEY` — set a meaningful key.
- **[info]** `REFRESH itab` is obsolete — `CLEAR itab`. For a table with a header line (legacy) `CLEAR itab[]` clears the body, `CLEAR itab` — the header; `REFRESH` — only the body.
- **[P2]** Internal table type — by access pattern: `HASHED` (large, filled at once, read only by full key) / `SORTED` (order needed or read by partial key) / `STANDARD` (small, index access, `APPEND`); no key needed — `WITH EMPTY KEY`.
- **[P3]** A single row — `READ TABLE` with `ASSIGNING`/`REFERENCE INTO` (or `itab[ key ]`), not `LOOP AT ... EXIT`.
- **[P1]** An internal table index is 1-based: `itab[ 0 ]` / `READ TABLE ... INDEX 0` is always wrong (no such row). Never treat `0` as a valid index.
- **[P3]** A missing row is normal: `VALUE #( itab[ key ] OPTIONAL )` (no row → `IS INITIAL`) or `VALUE #( itab[ key ] DEFAULT ls_dflt )` instead of `TRY`/`CATCH cx_sy_itab_line_not_found`.
- **[P2]** No double read: not `line_exists( )` + a repeated `READ`. If the row must exist — `TRY` + `CATCH cx_sy_itab_line_not_found` and your own exception.
- **[P2]** `sy-tabix` is valid only immediately after `READ TABLE`/`LOOP` (index of the current row). The next statement over the table (`READ`, `SORT`, `DELETE`, `APPEND`) overwrites it — save the index to a local variable before changes.
- **[P2]** Nested `LOOP AT` over two internal tables (searching the second's row for each first) — O(n²): move the read to `READ TABLE … WITH KEY`/`itab[ key ]`, or build an index table in one pass (`key → sy-tabix`).
- **[P3]** Grouping — `LOOP AT itab INTO ... GROUP BY ...` + `LOOP AT GROUP` (7.40+), not control-level `AT NEW`/`AT END OF` (those require a pre-`SORT`, non-obvious).
- **[P2]** Reading a row — always `ASSIGNING <fs>` (or `REFERENCE INTO`/`itab[ key ]`): no copy, editing `<fs>` edits the table. `INTO data(ls)` — only when a copy is exactly what you need (mutating separately from the table). `READ TABLE ... INTO <fs>` is forbidden — writes under the field-symbol instead of reassigning.
- **[P2]** `COLLECT` — only for `HASHED` or `SORTED ... WITH UNIQUE KEY` (for others — degradation to linear search).
- **[P1]** `BINARY SEARCH` — only on a table sorted by its key fields (re-`SORT` after `APPEND`); `DELETE ADJACENT DUPLICATES` — only after `SORT` by the `COMPARING` fields.

# Strings

- **[P1]** A slice `dobj+off(len)` (and `substring( val = … off = … len = … )`) raises `CX_SY_RANGE_OUT_OF_BOUNDS` (dump `STRING_OFFSET_TOO_LARGE`) if `[off, off+len)` is not entirely inside the string: empty/short string, `off` past the end. True for both `string` and `c` (for `c`, additionally `len = 0` is invalid); "return an empty string" only comes from an explicit `len = 0` for `string`, not from cutting at the boundary. Fix: `IF strlen( lv_s ) >= off + len` before the slice, or `CATCH cx_sy_range_out_of_bounds`; a slice from the edge — `left`/`right` (they cut at the boundary).
- **[P1]** `find( )` not found → `-1` (not `0`, not an exception); `occ = -1` — the last occurrence from the end; `occ = 0` — invalid (`CX_SY_STRG_PAR_VAL`).
- **[P1]** `replace( )`: `occ = 0` — replace ALL occurrences, default (`occ = 1`) — only the first. Without `sub`/`pcre` (only `off`/`len`) — replace a span by position; insert without replace — `insert( val = ... sub = ... off = ... )`.
- **[P2]** Stripping/padding leading zeros in NUMC keys (`PERNR`, `MATNR`, …) — `|{ x ALPHA = OUT }|`/`CONVERSION_EXIT_ALPHA_OUTPUT` (strip) and `|{ x ALPHA = IN }|`/`CONVERSION_EXIT_ALPHA_INPUT` (pad), not `SHIFT ... LEFT DELETING LEADING '0'` (fragile: does not distinguish "all zeros" from an empty string, breaks symmetry with reverse ALPHA input).
- **[P1]** `strlen( )` counts trailing spaces only in `string`: `strlen( 'abc   ' ) = 3` (`c` literal, fixed length), `strlen( \`abc   \` ) = 6` (`string` literal). `numofchar( )` counts no spaces anywhere.

# Domains (fixed values) and GUID

- **[P3]** Text/value of a fixed-value domain — `cl_reca_ddic_doma` (RE-FX): `get_text_by_value( EXPORTING id_name = <domain> id_value = <value> IMPORTING ed_text = <text> )`; reverse `get_value_by_text( EXPORTING id_name id_text if_ignore_case = abap_true IMPORTING ed_value EXCEPTIONS not_found = 1 )`; full list — `get_values( EXPORTING id_name IMPORTING et_values )` (rows with `ddtext`). Do not map value↔text by hand. Without RE-FX — FM `DD_DOMVALUES_GET`/`DDIF_DOMA_GET`.
- **[info]** Attributes/text of a data element (field label, length) — `cl_rec_ddic_dtel` (RE-FX, analog of `cl_reca_ddic_doma` but for a dtel, not a domain); not used in the repo, verify the signature in SE24. Standard — FM `DDIF_DTEL_GET`.
- **[P3]** GUID — `cl_reca_guid=>guid_create( IMPORTING ed_guid_22 = DATA(lv_guid) )` (22 chars, C22); do not assemble by hand from `sy-uzeit`/random. Without RE-FX — `cl_system_uuid=>create_uuid_c22_static( )` (7.50+, catch `cx_uuid_error`).
