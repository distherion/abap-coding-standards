# Open SQL

- **[P2]** No `SELECT *` in your own code (in others' — P3, see "Review vs own code").
- **[info]** Host variables in Open SQL — via `@`-escaping: `@lv_x`, `@DATA(...)`. An inline table constructor as a write source is `@( VALUE #( ... ) )` (`INSERT`/`MODIFY ... FROM @( VALUE #( ... ) )`) — distinct from a host variable `@lv_x`.
- **[P2]** Open SQL (ABAP SQL), not Native SQL (`EXEC SQL`): no syntax check, DB-specific, silently breaks when the DB changes. ADBC (`cl_sql_statement` with `?`-placeholders) — only for a dynamic case where static Open SQL is impossible (see `security.md`).
- **[P2]** Types in `SELECT ... INTO [CORRESPONDING]` must match the DDIC types of the columns: a mismatch (`numc`→`char`, different `p` length) silently converts/truncates. Check the target structure against the table.
- **[P1]** `FOR ALL ENTRIES` — only after an emptiness check. <!-- rule: for-all-entries-check-empty -->
- **[info]** On HANA `FOR ALL ENTRIES` is rewritten by the DB **into a join-based access path** instead of the classic key transfer (SAP Note 1662726 "Optimization of select with FOR ALL ENTRIES on SAP HANA database" — the term "FDA" is not official SAP terminology; related parameter note 1987132 — verify in the note). FAE stays relevant on HANA; a very large RANGE `IN` can be slower than FAE — measure with ST05, do not decide by rule of thumb.
- **[info]** An internal table as an ABAP SQL source (`SELECT ... FROM @itab AS alias`) — from 7.52, NOT 7.50 (see style.md "Version: what is NOT in 7.50"). Only when SQL functionality (JOIN/aggregates/subqueries) is needed beyond `LOOP`/`READ` — otherwise ABAP statements are faster. Moving data to the DB silences the pragma `##itab_db_select`; more than one table per statement — only via the in-memory engine without moving.
- **[P2]** For selection by a list of keys prefer **RANGE + `IN`**, not `FOR ALL ENTRIES` — faster. A RANGE has a statement-size limit: when the `WHERE` condition with `IN` exceeds it, Open SQL raises `CX_SY_OPEN_SQL_DB` (unhandled — dump `SAPSQL_STMNT_TOO_LARGE`/`DBSQL_STMNT_TOO_LARGE`). Catch it and fall back to FAE **only for this size case** — for any other DB error re-raise the exception, a blind FAE fallback would hide the real fault. **An empty RANGE makes `IN` true — it selects ALL rows** — check the emptiness BEFORE the query, not in the `CATCH` block. Equivalence with FAE — only for `EQ` rows; split `BT`/`EXCL` intervals into chunks first:
  ```abap
  TYPES ty_pernr_range TYPE RANGE OF pernr.
  IF lt_pernrs IS INITIAL.
    RETURN.  " empty list — no query at all (an empty RANGE in IN would select all rows)
  ENDIF.
  DATA(lt_pernr_range) = VALUE ty_pernr_range(
    FOR ls IN lt_pernrs ( sign = 'I' option = 'EQ' low = ls-pernr ) ).
  TRY.
      SELECT pernr, endda FROM pa0001 INTO TABLE @lt_pa0001
        WHERE pernr IN @lt_pernr_range AND endda = @lv_endda.
    CATCH cx_sy_open_sql_db.
      " cause is known here — the size limit; for other DB errors re-raise instead
      SELECT pernr, endda FROM pa0001 INTO TABLE @lt_pa0001
        FOR ALL ENTRIES IN lt_pernr_range
        WHERE pernr = @lt_pernr_range-low AND endda = @lv_endda.
  ENDTRY.
  ```
- **[P2]** Where the target rows come from a joinable relationship, prefer `JOIN` over `FOR ALL ENTRIES`/RANGE-`IN`: the join matches and filters on the DB without transferring a key list from the application to the DB (FAE/RANGE — when a direct join is not expressible; see the rules above for the size limit and the emptiness check).
- **[info]** Check that the `WHERE` condition is covered by an index (SE11/`ST05`); for a quick data probe — `UP TO n ROWS`.
- **[P2]** No `SELECT` in a row-processing loop — not `SELECT SINGLE`, not `SELECT ... ENDSELECT`: collect keys and select once (`SELECT`/`JOIN`/subquery) into `INTO TABLE`/`INTO CORRESPONDING FIELDS OF TABLE`; for large volumes — `PACKAGE SIZE`/cursor. (Note: the DB interface transfers rows in packets, not row-by-row — the real problem is the per-row processing loop and cursor handling, not a "row-by-row fetch".)
- **[P2]** Do aggregation and `GROUP BY`/`HAVING`/`[NOT] EXISTS` in SQL, do not fetch all rows and count in ABAP (`LOOP AT END OF`).
- **[P2]** `SELECT SINGLE` by a partial key without `ORDER BY` is non-deterministic. Need a specific row among many — `SELECT ... UP TO 1 ROWS ... ORDER BY`; existence check — `SELECT SINGLE @abap_true ...` without field transport.
- **[P2]** Millions of rows — in packages: `PACKAGE SIZE` or `OPEN CURSOR` + `FETCH ... PACKAGE SIZE`; do not fetch everything into memory. Do **not** `COMMIT WORK` inside the cursor loop/`SELECT` loop — a DB commit closes all open DB cursors, the next `FETCH` fails. Commit per package only if each package is read in its own independent `SELECT` (e.g. split by key), or commit once after the last `FETCH`/`CLOSE`.
- **[P1]** Buffer: a SELECT on a buffered table must go by the full key (full generic key, `=` via `AND`); `JOIN`/`DISTINCT`/aggregates/`ORDER BY` not by key/`CLIENT SPECIFIED`/native buffer bypass it; do not join a buffered table — `FOR ALL ENTRIES`. <!-- rule: buffer-needs-full-key -->
- **[P2]** Client: do not write `MANDT` in `WHERE` by hand — the implicit client handling adds it itself (in `JOIN` — client equality in `ON`); another client — `USING CLIENT` (7.40 SP05+), not `CLIENT SPECIFIED` (disables implicit handling and bypasses the buffer). All clients at once — `USING ALL CLIENTS` (only from 7.54, unavailable in 7.50). `USING CLIENT`/`CLIENT SPECIFIED` — under strict-mode ABAP SQL (from 7.40 SP05); in strict mode `CLIENT SPECIFIED` is forbidden for CDS/temporary tables.
- **[P1]** `LEFT/RIGHT OUTER JOIN`: conditions on the outer (for LEFT — right) side — only in `ON`, not in `WHERE` (the join degenerates into inner); unmatched rows give NULL → `COALESCE`. <!-- rule: outer-join-condition-on -->
- **[P2]** A text table (`*T`) via `INNER JOIN` — the row disappears if there is no translation. Texts — `LEFT JOIN` + `COALESCE`, or read separately by key.
- **[P2]** Without `ORDER BY` the row order is not guaranteed (unstable on HANA). `ORDER BY` runs on the DB — beneficial only when covered by an index; large unindexed sets are often cheaper to sort in ABAP.
- **[P3]** Count/concatenate/cast types on the DB — SQL expressions `CASE`/`CAST`/`COALESCE`/string functions (in 7.50 also allowed in `WHERE`/`HAVING`/`ON`); careful: a function over a column in `WHERE` blocks the index.
- **[P2]** `SELECT SINGLE ... FOR UPDATE` — a row lock on the DB (not the same as `ENQUEUE`): full primary key required (otherwise `sy-subrc=8`); held until the end of the LUW (`COMMIT`/`ROLLBACK`). `NOWAIT` is available only from a newer release (≈7.53), and `SKIP LOCKED` does **not exist** in ABAP SQL at all — in 7.50 a held lock makes the statement wait (and a deadlock raises an exception rather than returning `sy-subrc=6`).
- **[P2]** Profile before optimizing: ST05 (SQL trace), SAT (ABAP trace/call statistics), a HANA explain/PlanViz where relevant — do not guess the bottleneck from the code alone (it is often not where you think).
