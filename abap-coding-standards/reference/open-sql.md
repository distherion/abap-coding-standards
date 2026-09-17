# Open SQL

> Reading and writing the database: performance, buffering, client handling, joins and aggregates, the array/bulk statements.
> Related: `ddic.md` (table keys and buffering flags), `data.md` (the types rows land in), `security.md` (dynamic SQL and authorization), `cds-amdp.md` (what belongs in the database instead).

- **[P2]** No `SELECT *` in your own code (in others' — P3, see "Review vs own code").
- **[P3]** Host variables in Open SQL — via `@`-escaping (`@lv_x`, `@DATA(...)`); an unescaped host variable (`lv_x`) is the obsolete form. An inline table constructor as a write source is `@( VALUE #( ... ) )` (`INSERT`/`MODIFY ... FROM @( VALUE #( ... ) )`) — distinct from a host variable `@lv_x`.
- **[P2]** Open SQL (ABAP SQL), not Native SQL (`EXEC SQL`): no syntax check, DB-specific, silently breaks when the DB changes. ADBC (`cl_sql_statement` with `?`-placeholders) — only for a dynamic case where static Open SQL is impossible (see `security.md`).
- **[P2]** Types in `SELECT ... INTO [CORRESPONDING]` — the target must be **compatible** with the DDIC column types: a mismatch (`numc`→`char`, different `p` length/decimals) silently converts/truncates. Use the Dictionary→ABAP mapping deliberately (e.g. `numc`→`char` may be intended), check the target structure against the table.
- **[P1]** `FOR ALL ENTRIES` — only after an emptiness check. <!-- rule: for-all-entries-check-empty -->
- **[info]** On HANA `FOR ALL ENTRIES` is transformed by the DBSL hint `RSDU_CREATE_HINT_FAE` **into a join-based access path** instead of the classic key transfer; FAE stays relevant on HANA, though a very large RANGE `IN` can be slower.
- **[info]** An internal table as an ABAP SQL source (`SELECT ... FROM @itab AS alias`) — see `style.md`, "Version". Only when SQL functionality (JOIN/aggregates/subqueries) is needed beyond `LOOP`/`READ` — otherwise ABAP statements are faster. Moving data to the DB silences the pragma `##itab_db_select`.
- **[P2]** For selection by a list of keys prefer **RANGE + `IN`** over `FOR ALL ENTRIES` — the query stays declarative and the range list is reusable in several checks. A RANGE has a statement-size limit: when the `WHERE` condition with `IN` exceeds it, Open SQL raises `CX_SY_OPEN_SQL_DB` (unhandled — dump `SAPSQL_STMNT_TOO_LARGE`/`DBSQL_STMNT_TOO_LARGE`). Catch it **and check `cx->textid = cx_sy_open_sql_db=>statement_too_large`** before falling back to FAE — a fallback for any other DB error would hide the real fault. The empty-list trap is the same defect (see `for-all-entries-check-empty` above). Equivalence with FAE — only for `EQ` rows **and the same projection**: FAE treats its source table as a set — duplicate lines over the selected/`WHERE`-referenced columns are collapsed, lines with all-initial referenced columns are dropped — so the fallback equals the `IN` query only when that query is de-duplicated over the same columns too (`DISTINCT` below); select the full unique key in both branches if the duplicates are real records. Split `BT`/`EXCL` intervals into chunks first:
  ```abap
  " the P1 empty-range guard above applies
  DATA(lt_range) = VALUE ty_pernr_range( FOR ls IN lt_pernrs ( sign = 'I' option = 'EQ' low = ls-pernr ) ).
  TRY.
      SELECT DISTINCT pernr, endda FROM pa0001 INTO TABLE @lt_pa0001
        WHERE pernr IN @lt_range AND endda = @lv_endda.
    CATCH cx_sy_open_sql_db INTO DATA(lx_sql).
      " fall back to FAE only when the cause really is the statement-size limit
      IF lx_sql->textid <> cx_sy_open_sql_db=>statement_too_large.
        RAISE EXCEPTION lx_sql.
      ENDIF.
      SELECT DISTINCT pernr, endda FROM pa0001 INTO TABLE @lt_pa0001
        FOR ALL ENTRIES IN @lt_range WHERE pernr = @lt_range-low AND endda = @lv_endda.
  ENDTRY.
  ```
- **[P2]** Where the target rows come from a joinable relationship, prefer `JOIN` over `FOR ALL ENTRIES`/RANGE-`IN`: the join matches and filters on the DB without transferring a key list from the application to the DB. FAE/RANGE — only when a direct join is not expressible (limits, emptiness check and the fallback mechanics — in the RANGE rule above).
- **[info]** Check that the `WHERE` condition is covered by an index (SE11/`ST05`); for a quick data probe — `UP TO n ROWS`. Before optimizing, profile — ST05 (SQL trace), SAT (ABAP trace/call statistics), a HANA explain/PlanViz where relevant: do not guess the bottleneck from the code alone.
- **[P2]** No `SELECT` in a row-processing loop — not `SELECT SINGLE`, not `SELECT ... ENDSELECT`: collect keys and select once (`SELECT`/`JOIN`/subquery) into `INTO TABLE`/`INTO CORRESPONDING FIELDS OF TABLE`; for large volumes — `PACKAGE SIZE`/cursor. (Note: the DB interface transfers rows in packets, not row-by-row — the real problem is the per-row processing loop and cursor handling, not a "row-by-row fetch".)
- **[P2]** Do aggregation and `GROUP BY`/`HAVING`/`[NOT] EXISTS` in SQL, do not fetch all rows and count in ABAP (`LOOP AT END OF`).
- **[P2]** `SELECT SINGLE` by a partial key without `ORDER BY` is non-deterministic. Need a specific row among many — `SELECT ... UP TO 1 ROWS ... ORDER BY`; existence check — `SELECT SINGLE @abap_true ...` without field transport. `SELECT SINGLE` itself takes **no** `ORDER BY` (a 7.50 syntax error, the clause is not allowed there) — so this is a rewrite of the statement into `SELECT ... INTO TABLE @DATA(lt) UP TO 1 ROWS.` + `READ TABLE lt INTO ls INDEX 1.`, not an added clause.
- **[P2]** Millions of rows — in packages: `PACKAGE SIZE` or `OPEN CURSOR` + `FETCH ... PACKAGE SIZE`; do not fetch everything into memory. Do **not** `COMMIT WORK` inside the cursor loop/`SELECT` loop — a DB commit closes all open DB cursors, the next `FETCH` fails. Commit per package only if each package is read in its own independent `SELECT` (e.g. split by key), or commit once after the last `FETCH`/`CLOSE`.
- **[P1]** Buffer: a SELECT on a buffered table must go by the full key (full generic key, `=` via `AND`); `JOIN`/`DISTINCT`/aggregates/`ORDER BY` not by key/`CLIENT SPECIFIED`/native buffer bypass it; do not join a buffered table. `FOR ALL ENTRIES` on a buffered table is allowed only when the generic area is specified exactly (no `OR` between multiple generic areas) — otherwise the buffer is bypassed (ABAPDocu "Buffering, Restrictions"). <!-- rule: buffer-needs-full-key -->
  The full generic key means **all** its fields compared with `=`, joined by `AND` — the client is part of it (see the client rule below).
- **[P2]** Client: do not write `MANDT` in `WHERE` by hand — the implicit client handling adds it itself (in `JOIN` — client equality in `ON`); another client — `USING CLIENT` (7.40 SP05+), not `CLIENT SPECIFIED` (disables implicit handling and bypasses the buffer). All clients at once — `USING ALL CLIENTS` (only from 7.54, unavailable in 7.50 — see `style.md`, "Version"). `USING CLIENT`/`CLIENT SPECIFIED` — under strict-mode ABAP SQL (from 7.40 SP05); in strict mode `CLIENT SPECIFIED` is forbidden for CDS/temporary tables.
- **[P1]** `LEFT/RIGHT OUTER JOIN`: conditions on the outer (for LEFT — right) side — only in `ON`, not in `WHERE` (the join degenerates into inner); unmatched rows give NULL → `COALESCE`. <!-- rule: outer-join-condition-on -->
- **[P2]** A text table (`*T`) via `INNER JOIN` — the row disappears if there is no translation. Texts — `LEFT JOIN` + `COALESCE`, or read separately by key.
- **[P2]** Without `ORDER BY` the row order is not guaranteed (unstable on HANA). `ORDER BY` runs on the DB — beneficial only when covered by an index; large unindexed sets are often cheaper to sort in ABAP.
- **[P3]** Count/concatenate/cast types on the DB — SQL expressions `CASE`/`CAST`/`COALESCE`/string functions (in 7.50 also allowed in `WHERE`/`HAVING`/`ON`); careful: a function over a column in `WHERE` blocks the index.
- **[P2]** `SELECT SINGLE ... FOR UPDATE` — a row lock on the DB (not the same as `ENQUEUE`): full primary key required (otherwise `sy-subrc=8`); held until the end of the LUW (`COMMIT`/`ROLLBACK`). `NOWAIT` is available only from a newer release (≈7.53 — see `style.md`, "Version"), and **does not exist:** `SKIP LOCKED` in ABAP SQL — in 7.50 a held lock makes the statement wait (and a deadlock raises an exception rather than returning `sy-subrc=6`).
