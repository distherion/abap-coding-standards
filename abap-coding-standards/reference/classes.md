# Classes

> General Clean ABAP principles (not 7.50-specific) — apply as style, not as a hard ABAP constraint.
> Class design, method body and testability. Signatures, call syntax, parameter passing and type compatibility — `signatures.md`; test classes, doubles and DI — `testing.md`.

- **[P3]** Objects instead of static classes (static — only stateless utilities).
- **[P3]** Composition over inheritance; `FINAL` and `PRIVATE` by default. `FINAL` does not block test doubles: the double substitutes an object implementing the **interface**, not the class (see the factory/testability bullet below) — keep a dependency `FINAL` and substitute on its `zif_*`.
- **[P3]** Immutable over mutable+getter/setter (`CREATE OBJECT` → `NEW`: see `style.md`).
- **[P3]** Factories/patterns — only when actually needed, not for the future: a static factory instead of optional constructor parameters (global `CREATE PRIVATE`, constructor `PUBLIC`); do not introduce an interface for a *hypothetical* future. Exception — **testability is a current need**: a class that a unit-tested class depends on and that must be replaced by a double gets a `zif_*` interface immediately (injected via the constructor; substitution — see `testing.md`). The class under test itself needs no interface: it is tested directly through its public API.
- **[P3]** A static method via `zcl_x=>method( )`, not `lo_obj->method( )`; singleton — only when multiple instances make no sense.
- **[P3]** Constants/types — via `zif_x=>c_*`/`cl_x=>ty_*`, not `me->`.
- **[P2]** Do not mix stateful and stateless in one class.
- **[P1]** `STATIC`/class attributes — not for request state: they live in the **internal session** (per main program instance), not "in a work process" — a static from one request can be seen by the next one in the same session. Keep in statics only constants and non-session cache; session state — in instance attributes or local variables, or reset it explicitly. <!-- rule: static-not-request-state -->
- **[P2]** Public methods in integration/service classes — via an interface (`zif_*`) mandatory (substitution — see `testing.md`). In simple value-object/domain classes, public without an interface is acceptable if the class is `FINAL` and substitution is not expected.
- **[P2]** Do not bloat a class (anti-God-object): as the number of methods/attributes grows — split by responsibility.
- **[P2]** Do not allow cyclic class dependencies (A→B→A): they break DI and test-double substitution, hinder tests. Dependencies — one way; break the cycle with an interface/relocating responsibility.
- **[P3]** The Law of Demeter: talk to your immediate collaborators only — no long call chains `a->b->c->m( )` / `lo_obj->get_part( )->get_detail( )->get_value( )`; the intermediate object exposes the needed method itself (`lo_obj->get_value( )`). A long chain tightly couples the caller to the whole object graph.
- **[P2]** Do not use `MESSAGE`/list-processing in a global class: the class does not write to the UI. `MESSAGE ... INTO DATA( ... )` to populate the message list/`sy-` fields is fine (see `logging.md`). Errors — exceptions (`zcx_*`); output — at the top level/via a message list (`logging.md`).
- **[P2]** New code — classes/methods: do not create new `FORM` and non-RFC `FM` (exception — RFC/BAPI wrappers, standard HR mechanisms and update function modules used with `CALL FUNCTION ... IN UPDATE TASK`, see `luw.md`); prefer classes over FM — even when the logic reduces to calls to standard FM/BAPI: wrap them in a class method, not your own FM.
- **[P2]** Do not create macros `DEFINE … END-OF-DEFINITION` — code-in-a-line: inside a macro you cannot set a breakpoint, tracing is blind; extract to a method. (Leave legacy `DEFINE` alone on review.)
- **[P3]** No empty section blocks in a class definition — `PUBLIC`/`PROTECTED`/`PRIVATE SECTION` with no members are removed; keep only the sections that contain declarations.

# Method body

- **[P3]** One task per method, one level of abstraction. "3–5 lines" — a guideline, not a hard limit: do not split for the sake of splitting (wrapper methods, growth in public/interface methods, worse tracing). A method > ~20–30 lines or with several abstraction levels — consider splitting.
- **[P2]** A method focuses either on the happy path or on error handling, not both (Clean ABAP): validate the preconditions first, then let the "sunny" path run to its end; error branches scattered through the middle of the main flow make the happy path unreadable.
- **[P3]** `CHECK`/`EXIT` in a loop — legal (loop control). **Outside** a loop they exit the processing block (both forms are legal ABAP — `CHECK`/`EXIT` have documented "exits processing blocks" variants). The style point is readability: for a method guard prefer explicit `IF … RETURN/RAISE`; do not flag `CHECK` outside a loop as an error (at most a style suggestion).
- **[P2]** Keep complexity in check: cyclomatic complexity of a method ≤ ~15, nesting depth ≤ ~5; beyond — extract branches/guard conditions into separate methods. (Exceptions — for errors, not for regular cases: `errors.md`.)
- **[P3]** Flatten nesting with early exits: guard conditions up front (`IF NOT ... RETURN`/`CONTINUE`/`CHECK`) instead of wrapping the whole body in ever-deeper `IF` — the remaining happy path is linear.
- **[P2]** Remove dead code: unreachable after `RETURN`/`RAISE EXCEPTION`/`EXIT`/unconditional `CONTINUE`; `RETURN.` as the last statement of a method — also redundant (the method ends anyway); unused local variables/parameters/methods/types — remove too.
- **[P3]** No needless `CLEAR`: a local variable is initially empty — a `CLEAR` at the start/end of a method is dead code; keep it only before piecemeal filling of a structure (consecutive component assignments) or before reuse in a loop.
- **[P2]** Identical conditions in `IF`/`ELSEIF` (identical conditions) or the same body in different branches (identical contents) — a sign of an error/duplicate: collapse or rewrite.
- **[P2]** An empty `IF`/`ELSE`/`ELSEIF`/`CASE` branch (only `ENDIF`/`ENDCASE`, no statements) — either a redundant `IF` or a lost condition. Remove the empty branch or fill it.
- **[P2]** A guard added to a method that others call must accept every call that was legal before — walk the call sites first. Example: an equal-count check on two parallel tables (`lines( it_x ) = lines( it_y )`) rejects a legal call that passes fewer keys than rows (the spare rows need no override) — the scenario breaks on a message that names something else, not the new guard.

# Testability and dependency injection

- **[P3]** Wrap external dependencies (DB, FM, `AUTHORITY-CHECK`, `SY-DATUM`/`SY-UNAME`/`GET TIME STAMP`, files, messages/logs) in an interface wrapper (`zif_...`) — so they can be substituted with a test double.
- **[P2]** Inject dependencies — via the constructor by default; a setter — for optional/late-binding. A unit test does not go to the DB or external dependencies (FM/RFC/files) — only test doubles/DI.
- **How to write the tests themselves** (test classes, CUT, double injection, test data, assertions) — see `testing.md`.
