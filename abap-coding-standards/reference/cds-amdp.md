# CDS Views and AMDP

> ABAP 7.50. CDS (Core Data Services) for declarative data models and reads; AMDP (ABAP Managed Database Procedures) for mass HANA operations in SQLScript.

## CDS Views (DDL)

- **[info]** A CDS view — a `.ddls` file (DDL Source, ADT; SE11 shows the generated SQL view). One view — one `define view Z_I_... as select from ...`.
- **[P2]** Mandatory annotation: `@AbapCatalog.sqlViewName` (the SQL name under which the view is visible in Open SQL). `@AbapCatalog.compiler.compareFilter` — a compiler **performance option** (filter comparison), not mandatory. The technical CDS name — `Z_I_`/`Z_C_`, the SQL view — `Z...` without `/`.
- **[P2]** Fields and types — as in DDIC; the key — `key` on fields. Associations (`association [0..1]` / `[1..*]`) instead of JOIN in the main select; unfold via path expressions (`_Assoc.field`) or `$expand`.
- **[P2]** Do not duplicate logic in view and ABAP: computed fields, filters, aggregates — in CDS where possible; in ABAP — only what CDS lacks.
- **[P3]** Naming: `Z_I_` — interface/basic view (reusable, pure model), `Z_C_` — consumption view (over `Z_I_`, `@ObjectModel.*`/`@UI.*` annotations for Fiori/OData, no business logic in the select).
- **[P3]** Layering: one **basic view** (`Z_I_`) per DB table / table function; upper-layer views access the basic views, not the DB tables directly — the model's real field names, associations and annotations live in one place, and consumer changes cannot silently bypass them.
- **[P2]** No business logic in CDS — not only in consumption views: business conditions/rules in the select of a basic/intermediate view couple the model to the current process, break overlying views when they change and are untestable with ABAP Unit. A view stays a data model (row selection, associations); computations and conditions — in ABAP or AMDP, where they are unit-testable.
- **[info]** Input parameters (`with parameters`) — for parameterized reuse.

## AMDP

- **[P2]** AMDP — a class with a method `BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT OPTIONS READ-ONLY` (without `READ-ONLY` — for writes). The class must implement `IF_AMDP_MARKER_HDB` and declare the tables it uses in `USING`. Called only from an ABAP class (or another AMDP); not directly visible in Open SQL. No automatic client (`MANDT`) handling in the SQLScript body — several texts/filter by client explicitly where needed.
- **[P1]** An AMDP method does not `COMMIT`/`ROLLBACK` and does not write in Open SQL: all input/output — via `IMPORTING`/`EXPORTING`/`CHANGING` tables; the body — pure SQLScript.
- **[P2]** AMDP — for mass operations where Open SQL is inefficient (aggregating millions of rows, complex calculations over a set). A simple selection/single access — normal Open SQL, not AMDP.
- **[P2]** Security: the class/method name — from static code; build SQLScript without concatenating external input (otherwise injection). Parameters — via `:name` binding.
- **[info]** Exceptions from AMDP: `cx_amdp_error`, `cx_amdp_execution_failed` — catch and wrap in your own `zcx_*` (see `errors.md`).

## Reading CDS in Open SQL

- **[info]** A CDS view (with `@AbapCatalog.sqlViewName`) is read in Open SQL like a normal table: `SELECT ... FROM z_c_view ...`. Client handling — as for a table.
- **[P2]** Buffer: a CDS entity is not directly buffered in Open SQL; on frequent access, look at a view over tables with their own buffer.
