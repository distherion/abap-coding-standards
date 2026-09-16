# Data types, variables and references

> Types and their lifetime: declarations, inline `DATA`, references, structures and constructors.
> Related: `numbers.md` (money and arithmetic), `datetime.md` (date/time), `strings.md` (text), `itab.md` (internal tables).

## Variables and declarations

- **[info]** Inline `DATA(...)` instead of upfront blocks. **ABAP has no block scoping**: a variable declared inside `IF`/`LOOP`/`CASE`/`DO`/`TRY` (including `FIELD-SYMBOLS`) is visible to the end of the method — use below in the code is valid, do not flag it as an error.

- **[info]** One inline name (`DATA(x)`, `CATCH ... INTO data(x)`) cannot be declared twice in one method — that is a syntax error (not a review finding). Declare a variable used by several `CATCH`/loops once at method level (`DATA lx_error TYPE REF TO cx_root.`) and reuse it.

- **[P2]** No implicit data declarations: `TABLES` (declares an implicit table work area; not allowed in classes; only for exchange with classic-Dynpro screen fields in the program's global part — ABAPDocu: "No table work areas except for classic dynpros"), `NODES` (obsolete — interface work areas for logical databases only), `TYPE ... WITH HEADER LINE`/`TABLE ... WITH HEADER LINE` (legacy). Use `DATA` with an explicit type.

- **[P2]** Inline `DATA(x)` inside a branch (`IF`/`CASE`/`TRY` without `ELSE`/`CATCH`): if the branch did not run, the variable stays **initial** (the declaration is compiled regardless of the branch's execution) — using it below reads an empty value, not "not assigned". Declare before the branch or fill it in all branches.

- **[P2]** Inline `FIELD-SYMBOL(<fs>)` inside a branch: if the branch did not run, the field-symbol stays **unassigned** — dereferencing it below raises a runtime error, not "an empty value". After each possible `ASSIGN`/`READ INTO <fs>` check `IS ASSIGNED` or `sy-subrc`; a prior successful assignment is not guaranteed to survive a later re-`ASSIGN`. Declare before the branch or guarantee assignment in every path.

- **[P2]** Do not modify system fields (`sy-subrc`, `sy-tabix`, `sy-index`, `sy-datum`, …) — a style guideline, not a language restriction (a direct write is legal ABAP): a write is a side effect on shared runtime state that the next call/statement reads. Use a local variable for your own counter/flag.

- **[P2]** Shadowed variable: a local (`lv_*`/`DATA(x)`) named like an attribute/global hides it — the wrong one is read. Do not name locals like attributes.

- **[P2]** Do not use `sy-sysid`/`sy-sysuuid`/`sy-host` in business logic (ties to system/host). Identifiers — via configuration/constants.

- **[P3]** Initialization with a named type: `DATA(lv_x) = VALUE ty_type( ).` instead of `DATA lv_x TYPE ty_type.`; anonymous types (`TABLE OF … WITH KEY`, `WITH DEFAULT KEY`) cannot be declared inline — use `TYPE` there.

- **[P3]** No obsolete short declaration forms: `DATA lv_x.` is implicitly `c LENGTH 1`, `TYPES: t1, t2 TYPE p.` — implicitly `c`/standard lengths. Specify `TYPE`/`LENGTH`/`DECIMALS` explicitly (ABAPDocu "TYPES - implicit", obsolete language elements).


## References

- **[P1]** A reference variable is not a value — an **unbound** one addresses no object: `lo_ref->method( )` (an attribute read, a `->*` dereference) on it dumps `CX_SY_REF_IS_INITIAL`. Check `IS BOUND` before every dereference of a reference that can stay empty (an attribute set in one path only, a factory result, a chained `lo_a->lo_b->method( )`) and treat "unbound" as an error path — it is a crash, not "not found". A downcast (`?=`/`CAST`) is checked at runtime as well: a **bound** reference of an incompatible class dumps `CX_SY_MOVE_CAST_ERROR` — guard it with `IS INSTANCE OF` (`IF lo_obj IS INSTANCE OF zcl_x.`) before the cast. Neither check is a substitute for the other: an unbound reference is *not* an instance of anything, and casting an unbound one raises nothing — it returns an unbound target that dumps later at the first call. A reference created with `REF #( lv_local )` points at that exact data object and must not outlive it: do not return it, do not keep it in an attribute or a global when the object is a local of the method that created the reference. <!-- rule: ref-unbound-check -->

- **[info]** `REF #( )` instead of `GET REFERENCE OF` for data references.


## Structures and constructors

- **[P3]** `MOVE-CORRESPONDING` → `CORRESPONDING #( ... )`: explicit `MAPPING`/`EXCEPT`, the contract is visible, safer when the structure changes. **Behavior differs**: `MOVE-CORRESPONDING src TO dst` keeps the fields of `dst` that have no counterpart in `src`; `dst = CORRESPONDING #( src )` re-initializes them. Preserve untouched fields — `dst = CORRESPONDING #( BASE ( dst ) src )`; for internal/nested tables analyze the equivalent per row separately.

- **[P3]** Constructor operators (`VALUE`, `COND`, `SWITCH`, `CORRESPONDING`, `CONV`, `NEW`, `REDUCE`, `FILTER`, `REF`) — type via `#` when it is inferred from context: a typed variable/field, a typed method parameter, a table row. Explicit type (`COND type( )`, `VALUE type( )`) — only when the context gives no type: inline `DATA(...)` with no surrounding type, a generic parameter `c`/`n`/`x`, ambiguity (`DATA(x) = COND abap_bool( ... )`, `DATA(lt) = VALUE infty_tab( ... )`).
