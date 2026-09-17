# Internal tables

> The type for the access pattern, index and key semantics, reading, changing and iterating.
> Related: `data.md` (the element types a table is built of, variables and references), `open-sql.md` (filling a table from the database), `alv.md` (output from a table), `ddic.md` (a table type as a dictionary object).

- **[P1]** `INSERT INTO TABLE` into a table with a **unique** key: a duplicate of the primary key → `sy-subrc = 4` (`sy-tabix` is not set — check `sy-subrc`, not `sy-tabix`); a duplicate of a **unique secondary key** → the handleable exception `CX_SY_ITAB_DUPLICATE_KEY`; inserting a block where at least one row would duplicate → an uncatchable runtime error, not `sy-subrc`. An unhandled case aborts the program, so handle the exception or check the key with `line_exists( )` before the insert. <!-- rule: insert-duplicate-key-aborts -->
- **[P3]** `line_exists()` instead of `READ TABLE … NO FIELDS`; `LOOP AT … WHERE` instead of a nested `IF`.
- **[P1]** Do not delete table rows inside a loop (index shift → skips/duplicates). Collect keys and remove after the loop with one `DELETE ... WHERE key IN lt_range` — but `lt_range` must be a **selection table** (RANGE with `sign`/`option`/`low`/`high`), not a flat list of values; an **empty** range makes the condition always true (deletes **all** rows) — guard it. Or mark rows in the loop via a field-symbol (clear key fields) and delete `DELETE ... WHERE key IS INITIAL` — the second way only if living rows always have the key filled. <!-- rule: delete-rows-in-loop -->
  Legal (do not flag): `DELETE lt_x.` / `DELETE … INDEX sy-tabix` of the current row inside its own `LOOP AT lt_x`.
  Bad: `LOOP AT lt INTO <fs>. DELETE lt WHERE key = <fs>-key. ENDLOOP.` Good: collect the keys into a selection table, after the loop `DELETE lt WHERE key IN lt_range` — `lt_range = VALUE #( FOR wa IN lt ( sign = 'I' option = 'EQ' low = wa-key ) )` (an empty range would match all rows — guard it, see above).
- **[P1]** Do not modify the *whole* table inside its own loop — `SORT`, bulk `DELETE ... WHERE key IN ...`, `MODIFY`/`INSERT` affecting many rows inside `LOOP AT lt_x`: rows shift/duplicate and the iteration reads mutated data. Collect keys and apply the bulk change after the loop (same pattern as the `DELETE` rule above). <!-- rule: modify-table-in-loop -->
- **[P3]** No `DEFAULT KEY` — set a meaningful key.
- **[P3]** `REFRESH itab` is obsolete — `CLEAR itab`. For a table with a header line (legacy) `CLEAR itab[]` clears the body, `CLEAR itab` — the header; `REFRESH` — only the body.
- **[P2]** Internal table type — by access pattern: `HASHED` (large, filled at once, read only by full key) / `SORTED` (order needed or read by partial key) / `STANDARD` (small, index access, `APPEND` — insertion order, duplicates allowed); no key needed — `WITH EMPTY KEY`. `COLLECT` fits `HASHED`/`SORTED` (its key) and degrades to a linear search on `STANDARD`.
- **[P3]** A single row — `READ TABLE`, not `LOOP AT ... EXIT`.
- **[P1]** An internal table index is 1-based: `itab[ 0 ]` / `READ TABLE ... INDEX 0` is always wrong (no such row). Never treat `0` as a valid index. <!-- rule: itab-index-1-based -->
- **[P2]** A missing row is normal: read directly with `VALUE #( itab[ key ] OPTIONAL )` (no row → `IS INITIAL`) or `VALUE #( itab[ key ] DEFAULT ls_dflt )` instead of `TRY`/`CATCH cx_sy_itab_line_not_found`; no double read — not `line_exists( )` + a repeated `READ` (if the row must exist — `TRY` + `CATCH cx_sy_itab_line_not_found` and your own exception).
- **[P2]** `sy-tabix` is set only by `READ TABLE`/`LOOP AT` (and a few index statements); `DELETE` does **not** set it; after `ENDLOOP` its previous value is restored; a `READ` by hash key sets 0, an unsuccessful binary search may set the insertion position. Do not read `sy-tabix` after arbitrary statements over the table — save the index to a local variable before changes.
- **[P3]** `DESCRIBE TABLE itab LINES lv` → `lv = lines( itab )`; the index of a row → `line_index( itab[ ... ] )` (built-in table functions, 7.40+).
- **[P2]** Nested `LOOP AT` over two internal tables (searching the second's row for each first) — O(n²): move the read to `READ TABLE … WITH KEY`/`itab[ key ]`, or build an index table in one pass (`key → sy-tabix`).
- **[P3]** Grouping — `LOOP AT itab INTO ... GROUP BY ...` + `LOOP AT GROUP` (7.40+), not control-level `AT NEW`/`AT END OF` (those require a pre-`SORT`, non-obvious).
- **[P2]** Reading a row into a field-symbol — no copy: editing `<fs>` edits the table. `INTO data(ls)` — only when a copy is exactly what you need (mutating separately from the table). `READ TABLE ... INTO <fs>` is legal ABAP but **copies** the row into the data object `INTO` is currently bound to — the field-symbol itself stays bound to the same memory area (a new binding is created only by `ASSIGNING`); if `<fs>` is unassigned, `INTO <fs>` cannot be used as a target. Our project convention is to prefer `ASSIGNING`/`REFERENCE INTO` for clarity, not a language restriction.
  ```abap
  " wrong — a copy; the change is lost with ls
  READ TABLE lt_pernr INTO DATA(ls_pernr). ls_pernr-flag = 'X'.

  " right — a reference; the change lands in the table
  READ TABLE lt_pernr ASSIGNING FIELD-SYMBOL(<ls_pernr>). <ls_pernr>-flag = 'X'.
  ```
- **[P2]** `MODIFY itab FROM wa` without `TRANSPORTING` overwrites **every** field of the row, key fields included — a partially filled `wa` silently clears what it does not carry; `MODIFY ... FROM wa TRANSPORTING f1 f2` changes only the listed components (each must be a component of the line type, otherwise a syntax error). Same for `INSERT ... FROM wa`. A `MODIFY` by key that matched no row → `sy-subrc = 4` (nothing was changed), by index → `4` if the index does not exist: check it where the change is a business result.
- **[P1]** `BINARY SEARCH` — only on a table sorted by its key fields (re-`SORT` after `APPEND`); `DELETE ADJACENT DUPLICATES` — only after `SORT` by the `COMPARING` fields. <!-- rule: binary-search-needs-sort -->
