# Classes

> General Clean ABAP principles (not 7.50-specific) — apply as style, not as a hard ABAP constraint.

- **[P3]** Objects instead of static classes (static — only stateless utilities).
- **[P3]** Composition over inheritance; `FINAL` and `PRIVATE` by default.
- **[P3]** Immutable over mutable+getter/setter; `NEW #( )` instead of `CREATE OBJECT`.
- **[P3]** Factories/patterns — only when actually needed, not for the future: a static factory instead of optional constructor parameters (global `CREATE PRIVATE`, constructor `PUBLIC`); do not introduce abstraction upfront.
- **[P3]** A static method via `zcl_x=>method( )`, not `lo_obj->method( )`; singleton — only when multiple instances make no sense.
- **[P3]** Constants/types — via `zif_x=>c_*`/`cl_x=>ty_*`, not `me->`.
- **[P2]** Do not mix stateful and stateless in one class.
- **[P1]** `STATIC`/class attributes — not for request state: they live in the **internal session** (per main program instance), not "in a work process" — a static from one request can be seen by the next one in the same session. Keep in statics only constants and non-session cache; session state — in instance attributes or local variables, or reset it explicitly.
- **[P2]** Public methods in integration/service classes — via an interface (`zif_*`) mandatory (substitution with a test double). In simple value-object/domain classes, public without an interface is acceptable if the class is `FINAL` and substitution is not expected.
- **[P2]** Do not bloat a class (anti-God-object): as the number of methods/attributes grows — split by responsibility.
- **[P2]** Do not allow cyclic class dependencies (A→B→A): they break DI and test-double substitution, hinder tests. Dependencies — one way; break the cycle with an interface/relocating responsibility.
- **[P3]** The Law of Demeter: talk to your immediate collaborators only — no long call chains `a->b->c->m( )` / `lo_obj->get_part( )->get_detail( )->get_value( )`; the intermediate object exposes the needed method itself (`lo_obj->get_value( )`). A long chain tightly couples the caller to the whole object graph.
- **[P2]** Do not use `MESSAGE`/list-processing in a global class: the class does not write to the UI. `MESSAGE ... INTO DATA( ... )` to populate the message list/`sy-` fields is fine (see `logging.md`). Errors — exceptions (`zcx_*`); output — at the top level/via a message list (`logging.md`).
- **[P2]** New code — classes/methods: do not create new `FORM` and non-RFC `FM` (exception — RFC/BAPI wrappers, standard HR mechanisms and update function modules used with `CALL FUNCTION ... IN UPDATE TASK`, see `errors.md`); prefer classes over FM — even when the logic reduces to calls to standard FM/BAPI: wrap them in a class method, not your own FM.
- **[P2]** Do not create macros `DEFINE … END-OF-DEFINITION` — code-in-a-line: inside a macro you cannot set a breakpoint, tracing is blind; extract to a method. (Leave legacy `DEFINE` alone on review.)

# Signatures and method calls

- **[P2]** **Definition** (`METHODS`): sections strictly in order `IMPORTING → EXPORTING → CHANGING → RETURNING → RAISING`; a violation is a syntax error (`FORM` has only `USING`/`CHANGING`, `FUNCTION` has its own set — SE37 sets the order).
- **[P2]** **Call** (parenthesized): `EXPORTING → IMPORTING → CHANGING → RECEIVING`. The call order **differs** from the definition order!
- **[P3]** **Mixed calls**: `IMPORTING` and `CHANGING` in a call cannot be omitted. `EXPORTING` can be omitted only when it is the only call section (no `IMPORTING`, `CHANGING` and `RECEIVING`) — with any of them, `EXPORTING` must be explicit. `RECEIVING` — the word itself can be omitted only when there is no `CHANGING`. Examples: `do( iv_x = lv )` (only importing — the word omitted); `do( EXPORTING iv_x = lv RECEIVING rv = lv2 )` (there is RECEIVING — EXPORTING explicit); `do( EXPORTING iv_x = lv CHANGING cs_y = lv2 )`; `do( CHANGING cs_x = lv )`.
- **[P3]** **Formatting calls with parameters** (SAP pretty-printer): the first named parameter — on the line with `(`, the rest one per line; names and `=` aligned into a column across all sections. One parameter (or none) — on one line; two or more — each on its own line:
  ```abap
  mo_service->fill_tech_fields( EXPORTING iv_begda     = lv_begda
                                          iv_endda     = lv_endda
                                 CHANGING cs_db        = ls_db ).
  ```
- **[P3]** The same `=`-alignment in `VALUE`/`NEW`/`CORRESPONDING` constructors; an empty constructor — `VALUE p0001( )`; a short `CORRESPONDING ... MAPPING` — on one line.
- **[P3]** A nested call as an argument value (`method( EXPORTING iv_x = other( ... ) CHANGING cs_y = ... )`): the nested call's parameters, starting on the line `iv_x = other(`, continue in the same `name_col`/`eq_col` as the outer call — one aligned block; the `CHANGING` section of the outer call after the nested call's closing `)` — again in the same `name_col`. Deeper nested expressions in a value (`COND #( ... )`, `VALUE ...( ... )`) align to their own bracket, not to the outer column.
- **[P3]** In calls prefer a functional call or `IMPORTING` over `RECEIVING`; self-reference `me->method( )` → `method( )`.
- **[P3]** ≤3 IMPORTING; one `RETURNING` instead of `EXPORTING` where possible; do not mix `RETURNING`+`EXPORTING`.
- **[P3]** The `RETURNING` parameter — uniform across the project (`result` or `rv_*` per the prefix convention); the name does not repeat the type/value. `PREFERRED PARAMETER` — rarely, do not introduce for one call site.
- **[P2]** A method whose behavior changes by a flag or `IS SUPPLIED` (a boolean parameter, except `SET_*`, and extra `OPTIONAL` parameters) does two things — split into separate methods: `update( )` / `update_and_save( )`, not `update( do_save = abap_true )`.
- **[P2]** Many related parameters (fields of an object, context dependencies, fields of an error) — group into a `ty_*` structure and pass one `is_*`/`cs_*`, not a dozen scalars. An `OPTIONAL` scalar in a structure loses `IS SUPPLIED` — distinguish an optional field with a flag (`has_*`).
- **[P2]** Large structures/tables in `IMPORTING` without `VALUE` (or `REFERENCE`) are passed by reference; with `VALUE` — passed by value with copy-on-write (the data is not physically copied until the callee writes). If the parameter does not change — do not take it by value.
- **[P1]** An `IMPORTING` parameter (without `VALUE`) — a reference to the caller's data: do not modify it and do not pass it into another procedure's `CHANGING` (silently corrupts others' data, like `hrtnnnn_tab = it_attrib`). You may modify only an object via `REF TO`. Need to modify the input table/structure — copy to a local variable.
- **[P1]** An `EXPORTING` parameter without `VALUE`: guarantee a write on all branches or `CLEAR` at the start — otherwise the caller gets stale data; `VALUE`/`RETURNING` are empty by definition, do not clear them. Input and output are the same variable → redesign to `RETURNING` (an early `CLEAR` would eat the input).

# Method body

- **[P3]** One task per method, one level of abstraction. "3–5 lines" — a guideline, not a hard limit: do not split for the sake of splitting (wrapper methods, growth in public/interface methods, worse tracing). A method > ~20–30 lines or with several abstraction levels — consider splitting.
- **[P2]** `CHECK`/`EXIT` in a loop — legal (loop control). **Outside** a loop they exit the processing block (both forms are legal ABAP — `CHECK`/`EXIT` have documented "exits processing blocks" variants). The style point is readability: for a method guard prefer explicit `IF … RETURN/RAISE`; do not flag `CHECK` outside a loop as an error (at most a style suggestion).
- **[P3]** Exceptions — for errors, not for control flow.
- **[P2]** Keep complexity in check: cyclomatic complexity of a method ≤ ~15, nesting depth ≤ ~5; beyond — extract branches/guard conditions into separate methods.
- **[P2]** Remove dead code: unreachable after `RETURN`/`RAISE EXCEPTION`/`EXIT`/unconditional `CONTINUE`; `RETURN.` as the last statement of a method — also redundant (the method ends anyway); unused local variables/parameters/methods/types — remove too.
- **[P2]** Identical conditions in `IF`/`ELSEIF` (identical conditions) or the same body in different branches (identical contents) — a sign of an error/duplicate: collapse or rewrite.
- **[P2]** An empty `IF`/`ELSE`/`ELSEIF`/`CASE` branch (only `ENDIF`/`ENDCASE`, no statements) — either a redundant `IF` or a lost condition. Remove the empty branch or fill it.

# Testability and dependency injection

- **[P3]** Wrap external dependencies (DB, FM, `AUTHORITY-CHECK`, `SY-DATUM`/`SY-UNAME`/`GET TIME STAMP`, files, messages/logs) in an interface wrapper (`zif_...`) — so they can be substituted with a test double.
- **[P2]** Inject dependencies — via the constructor by default; a setter — for optional/late-binding. A unit test does not go to the DB or external dependencies (FM/RFC/files) — only test doubles/DI.
- **How to write the tests themselves** (test classes, CUT, double injection, test data, assertions) — see `testing.md`.
