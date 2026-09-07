# Open SQL

- **[P1]** No `SELECT *` in your own code (in others' — P3, see "Review vs own code").
- **[info]** Host variables in Open SQL — via `@`-escaping: `@lv_x`, `@DATA(...)`.
- **[P2]** Types in `SELECT ... INTO [CORRESPONDING]` must match the DDIC types of the columns: a mismatch (`numc`→`char`, different `p` length) silently converts/truncates. Check the target structure against the table.
- **[P1]** `FOR ALL ENTRIES` — only after an emptiness check.
- **[info]** An internal table as an ABAP SQL source (`SELECT ... FROM @itab AS alias`) — from 7.52, NOT 7.50 (see style.md "Version: what is NOT in 7.50"). Only when SQL functionality (JOIN/aggregates/subqueries) is needed beyond `LOOP`/`READ` — otherwise ABAP statements are faster. Moving data to the DB silences the pragma `##itab_db_select`; more than one table per statement — only via the in-memory engine without moving.
- **[P2]** For selection by a list of keys prefer **RANGE + `IN`**, not `FOR ALL ENTRIES` — faster. A RANGE has a limit: when exceeded, Open SQL raises `CX_SY_OPEN_SQL_DB` (unhandled — dump `SAPSQL_STMNT_TOO_LARGE`/`DBSQL_STMNT_TOO_LARGE`). Catch the exception and fall back to FAE; equivalence — only for `EQ` rows, split `BT`/`EXCL` intervals into chunks first:
  ```abap
  DATA(lt_pernr_range) = VALUE #( FOR ls IN lt_pernrs ( sign = 'I' option = 'EQ' low = ls-pernr ) ).
  TRY.
      SELECT pernr, endda FROM pa0001 INTO TABLE @lt_pa0001
        WHERE pernr IN @lt_pernr_range AND endda = @lv_endda.
    CATCH cx_sy_open_sql_db.
      " fall back only on statement-size overflow; re-raise any other DB error
      IF lt_pernr_range[] IS NOT INITIAL.
        SELECT pernr, endda FROM pa0001 INTO TABLE @lt_pa0001
          FOR ALL ENTRIES IN lt_pernr_range
          WHERE pernr = @lt_pernr_range-low AND endda = @lv_endda.
      ENDIF.
  ENDTRY.
  ```
- **[info]** Check that the `WHERE` condition is covered by an index (SE11/`ST05`); for a quick data probe — `UP TO n ROWS`.
- **[P2]** No `SELECT` in a row-processing loop (incl. `SELECT SINGLE`) — collect keys and select once with `SELECT`/`JOIN`/subquery.
- **[P2]** Do not use `SELECT ... ENDSELECT` (row-by-row fetch) — `INTO TABLE`/`INTO CORRESPONDING FIELDS OF TABLE`; for large volumes — `PACKAGE SIZE`/cursor.
- **[P2]** Do aggregation and `GROUP BY`/`HAVING`/`[NOT] EXISTS` in SQL, do not fetch all rows and count in ABAP (`LOOP AT END OF`).
- **[P2]** `SELECT SINGLE` by a partial key without `ORDER BY` is non-deterministic. Need a specific row among many — `SELECT ... UP TO 1 ROWS ... ORDER BY`; existence check — `SELECT SINGLE @abap_true ...` without field transport.
- **[P2]** Millions of rows — in packages: `PACKAGE SIZE` or `OPEN CURSOR` + `FETCH ... PACKAGE SIZE`, process and `COMMIT` per package (mass load); do not fetch everything into memory.
- **[P1]** Buffer: a SELECT on a buffered table must go by the full key (full generic key, `=` via `AND`); `JOIN`/`DISTINCT`/aggregates/`ORDER BY` not by key/`CLIENT SPECIFIED`/native buffer bypass it; do not join a buffered table — `FOR ALL ENTRIES`.
- **[P2]** Client: do not write `MANDT` in `WHERE` by hand — the implicit client handling adds it itself (in `JOIN` — client equality in `ON`); another client — `USING CLIENT` (7.40 SP05+), not `CLIENT SPECIFIED` (disables implicit handling and bypasses the buffer). All clients at once — `USING ALL CLIENTS` (only from 7.54, unavailable in 7.50). `USING CLIENT`/`CLIENT SPECIFIED` — under strict-mode ABAP SQL (from 7.40 SP05); in strict mode `CLIENT SPECIFIED` is forbidden for CDS/temporary tables.
- **[P1]** `LEFT/RIGHT OUTER JOIN`: conditions on the outer (for LEFT — right) side — only in `ON`, not in `WHERE` (the join degenerates into inner); unmatched rows give NULL → `COALESCE`.
- **[P2]** A text table (`*T`) via `INNER JOIN` — the row disappears if there is no translation. Texts — `LEFT JOIN` + `COALESCE`, or read separately by key.
- **[P2]** Without `ORDER BY` the row order is not guaranteed (unstable on HANA). `ORDER BY` runs on the DB — beneficial only when covered by an index; large unindexed sets are often cheaper to sort in ABAP.
- **[P3]** Count/concatenate/cast types on the DB — SQL expressions `CASE`/`CAST`/`COALESCE`/string functions (in 7.50 also allowed in `WHERE`/`HAVING`/`ON`); careful: a function over a column in `WHERE` blocks the index.
- **[P2]** `SELECT SINGLE ... FOR UPDATE [NOWAIT]` — a row lock on the DB (not the same as `ENQUEUE`): full primary key required (otherwise `sy-subrc=8`); on a held lock + `NOWAIT` → `sy-subrc=6`; held until the end of the LUW (`COMMIT`/`ROLLBACK`).
