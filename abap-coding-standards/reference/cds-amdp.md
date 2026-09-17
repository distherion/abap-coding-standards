# CDS Views and AMDP

> ABAP 7.50. CDS (Core Data Services) for declarative data models and reads; AMDP (ABAP Managed Database Procedures) for mass HANA operations in SQLScript.

## CDS Views (DDL)

- **[info]** One view — one `define view ... as select from ...`, in a `.ddls` file (DDL Source, ADT; SE11 shows the generated SQL view).
- **[P2]** Mandatory annotation: `@AbapCatalog.sqlViewName` (the SQL name under which the view is visible in Open SQL). `@AbapCatalog.compiler.compareFilter` — controls how join conditions are computed (`true` — the join expression is evaluated once, `false` — a separate join per condition; **default is `false`**), not a mandatory performance option.
- **[P2]** Fields and types — as in DDIC; the key — `key` on fields. Associations (`association [0..1]` / `[1..*]`) instead of JOIN in the main select; unfold via path expressions (`_Assoc.field`) in the CDS DDL (`$expand` is an OData mechanism, not a CDS DDL construct).
- **[P3]** Naming: `Z_I_` — interface/basic view (reusable, pure model), `Z_C_` — consumption view (over `Z_I_`, `@ObjectModel.*`/`@UI.*` annotations for Fiori/OData, no business logic in the select); the SQL view — `Z...` without `/`.
- **[P3]** Layering: one **basic view** (`Z_I_`) per DB table / table function; upper-layer views access the basic views, not the DB tables directly — the model's real field names, associations and annotations live in one place, and consumer changes cannot silently bypass them.
- **[P2]** No business logic in CDS, and no logic duplicated between view and ABAP: the view owns row selection, associations, computed fields and aggregates — ABAP keeps only what CDS cannot express. Business conditions and process rules do not belong in a select, not even in a basic/intermediate view: they couple the model to the current process, break overlying views when they change and are untestable with ABAP Unit — those go to ABAP or AMDP (a technical aggregation over a mass of rows in AMDP).
- **[info]** Input parameters (`with parameters`) — for parameterized reuse.

## AMDP

- **[P2]** AMDP — a class with a method `BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT OPTIONS READ-ONLY` (without `READ-ONLY` — for writes). The class must implement `IF_AMDP_MARKER_HDB` and declare the tables it uses in `USING`. The method is called like any class method — from any ABAP context (a class, a report, another AMDP); only Open SQL cannot call it. No automatic client (`MANDT`) handling in the SQLScript body — several texts/filter by client explicitly where needed.
- **[P2]** An AMDP method does not `COMMIT`/`ROLLBACK` and does not write in Open SQL: all input/output — via `IMPORTING`/`EXPORTING`/`CHANGING` tables; the body — pure SQLScript.
- **[P2]** AMDP — for mass operations where Open SQL is inefficient (aggregating millions of rows, complex calculations over a set). A simple selection/single access — normal Open SQL, not AMDP.
- **[P2]** Security: the class/method name — from static code; build SQLScript without concatenating external input (otherwise injection). Parameters — via `:name` binding.
- **[info]** Exceptions from AMDP: `cx_amdp_error`, `cx_amdp_execution_failed` — catch and wrap in your own `zcx_*` (see `errors.md`).

## Reading CDS in Open SQL

- **[P2]** Buffer: a CDS entity is not directly buffered in Open SQL; on frequent access, look at a view over tables with their own buffer.
