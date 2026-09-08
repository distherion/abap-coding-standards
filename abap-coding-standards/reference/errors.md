# Error handling

- **[P1]** Class-based exceptions (`CX_*`), not classic `RAISE`.
- **[P1]** Do not catch a broad `CATCH cx_root`/`cx_sy_*`-base — it swallows everything, including `CX_NO_CHECK`/system ones. Catch a concrete `zcx_*`/`cx_*` and wrap it (see below); if `CATCH cx_root` is unavoidable — re-raise or log, do not swallow.
- **[P3]** One base exception class per package; raise one type; subclasses — only so the caller can distinguish cases.
- **[info]** abapGit: an exception class (descendant of `CX_*`) in `.clas.xml` requires `<CATEGORY>40</CATEGORY>` (a normal class — 0); without it, it is created as a normal class (activation does not fail).
- **[info]** `CX_STATIC_CHECK` — expected (to propagate, declare in `RAISING`); `CX_DYNAMIC_CHECK` — avoidable, the caller checked preconditions (also `RAISING`, but the declaration check is at runtime); `CX_NO_CHECK` — system, no `RAISING` needed, always propagates (you can still `CATCH` it).
- **[P0]** Unrecoverable — cannot continue: stop processing and do not commit. Mechanism — by application type: `RAISE` up to the top level (there → message/HTTP 500), or log + abort. "Swallowed and moved on" — not allowed.
- **[P1]** Do not use `ASSERT` for business/invariant checks: it aborts the program with a dump, is meant for assumptions (and even with `ID`/`FIELDS` a *violated* assertion still aborts), and active assertions cannot be handled/relogged like class-based exceptions. Integrity/impossible-state checks — only `IF … RAISE` with a clear text, or explicit error handling. (`ASSERT` can be deactivated in a release — then the check silently disappears.)
- **[info]** `RAISE EXCEPTION`: `TYPE class` — empty; `TYPE class MESSAGE ...` — from a message; `NEW class( ... )` — with constructor parameters; a reference variable — an already-created one. A functional call after `RAISE EXCEPTION` (`RAISE EXCEPTION zcx_x=>factory( )`) is invalid — first `DATA(lx_err)`, then `RAISE EXCEPTION lx_err`. `RAISE EXCEPTION NEW ...` — only from 7.52, do not use in 7.50.
- **[info]** `MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH ...` (dynamic message) requires the exception class to implement `IF_T100_DYN_MSG`; a static `MESSAGE eNNN(class)` needs only `IF_T100_MESSAGE`. `WITH` fills `msgv1..4` only with `IF_T100_DYN_MSG`.
- **[info]** Exception class constructor: `previous TYPE REF TO cx_root OPTIONAL` (copy the signature only into a `CX_ROOT` descendant; the `!` before a parameter is cosmetic — do not write it by hand).
- **[P2]** Wrap others' exceptions (`cx_reca_symsg` and other `cx_*` of external components) in your own `zcx_*` — do not let them leak into your code.
- **[P1]** Fail fast: check preconditions at the start of the method.
- **[P2]** Write under a lock: `ENQUEUE_*` (enqueue server, not a DB lock) + check (`foreign_lock`); `DEQUEUE_*` at the end, in all branches, including `CLEANUP`.
- **[P2]** HR OM/PA — via classes: `set_exclusive_lock`/`remove_exclusive_lock`; release locks on **every** path — success, error and especially in `CLEANUP` (CLEANUP does not run on the normal success path or after a `CATCH` already handled the error — release explicitly on each branch). Write — trial pattern: `start_trial` → `approve_trial`+`flush(no_commit=abap_false)` / `discard_trial` in `CATCH`. (Interface `if_hrpa_masterdata`, class `cl_hrpa_masterdata`; verify signatures in SE24.)
- **[P1]** Check the result of a call with a status (`sy-subrc`, an HR FM's return structure, `et_message`, `ev_success`) immediately, before other calls/assignments: the next call overwrites the previous result → an error looks like success. Do not consider an operation successful until all checks pass.
- **[P2]** `SUBMIT ... AND RETURN` returns no result/error, `sy-subrc` after `SUBMIT` is unreliable: do not consider an operation successful from the `SUBMIT` return. Check the fact of the write afterwards (`READ`/`SELECT`) or use an FM/class with an explicit status.
- **[P2]** Synchronous `CALL FUNCTION ... DESTINATION` (RFC): handle `SYSTEM_FAILURE`/`COMMUNICATION_FAILURE` — an unhandled network/system error silently leaves the operation incomplete. (Errors of parallel tasks — `parallel.md`.)
- **[P2]** One logical operation = one `COMMIT WORK` at the end, after all checks. COMMIT "in chunks" — only in mass loading. (Splitting an LUW into independent `COMMIT`s — P1, see SKILL.md "Exception to downgrade".)
- **[P2]** User messages — only via message class SE91 (class/number as literals — otherwise where-used in SE91 disappears) or text elements `TEXT-xxx`; not a literal. Message parameters — `&1..&4`.
- **[P1]** An empty `CATCH` (immediately `ENDTRY`) is forbidden — swallowing an error: handle the exception or do not catch at all.

# Update task and V1/V2

- **[P2]** Deferred write: `CALL FUNCTION ... IN UPDATE TASK` — the FM runs in an update work process at `COMMIT WORK`. For debugging/synchronous run — `SET UPDATE TASK LOCAL`.
- **[P2]** V1 (critical) / V2 (secondary: statistics, indexes, background) — set by the update FM's **attributes** (`V1`/`V2` in the update module), not by `PERFORM ... ON COMMIT` (that is a **separate** older mechanism — the deferred code runs in the same work process at commit, no V1/V2 semantics). A V1 error → V2 does not run, the **update-task DB LUW** rolls back (the caller's already-committed direct writes remain); a V2 error → V1 is already committed.
- **[P2]** `COMMIT WORK AND WAIT` — synchronous: waits for **V1** update tasks to complete, `sy-subrc` shows their result; without `AND WAIT` update tasks run asynchronously, the result is not visible. (V2 runs later and is not awaited by `AND WAIT`.) Need the write result — `AND WAIT` (in dialog — delay; if the status is not needed, `COMMIT WORK` without `AND WAIT` is faster).
- **[P1]** An update FM must not commit itself: inside an update task `COMMIT WORK`/`ROLLBACK WORK` are forbidden (terminates the task). The whole transaction commits with the caller's single `COMMIT WORK`.

# Resumable exceptions

- **[info]** `RAISE RESUMABLE EXCEPTION ...` — the caller can `CATCH ... BEFORE UNWIND` and continue via `RESUME` (execution continues *after* the `RAISE`). `RETRY` — allowed in a normal `CATCH`: re-runs the whole `TRY` block from the start. Do not confuse them: `RETRY` repeats the block, `RESUME` continues after `RAISE` (and requires `BEFORE UNWIND`).
- **[P3]** Resumable — for "try again/substitute a value", not for normal errors: a normal error — a normal exception.
- **[P2]** `CATCH ... BEFORE UNWIND` is more expensive than a normal `CATCH` (does not unwind the stack, keeps context) — use deliberately, not by default.
