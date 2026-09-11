# Parallelism and background processes

- **[P2]** Parallel — only for data-independent chunks: mass load/calculation where rows do not affect each other. Order is not guaranteed; do not pass shared counters/flags via shared state.
- **[P1]** State does not cross the task boundary: each parallel task (RFC task, background job) — its own work process/session. ABAP memory (`EXPORT/IMPORT ... MEMORY ID`), `SET/GET PARAMETER`, class statics — NOT visible to the caller in parallel (see "Classes": static ≠ request state). Session state — only via call parameters/result. <!-- rule: state-not-cross-task -->
- **[P2]** Launch: `CALL FUNCTION ... STARTING NEW TASK taskname`, on completion — `WAIT UNTIL` / `RECEIVE RESULTS FROM FUNCTION`. The FM's exported **result** arrives via `RECEIVE`, never via `sy-subrc` after the `CALL`; `sy-subrc` after an async `CALL` reports only the predefined communication exceptions (`system_failure`/`communication_failure`/`resource_failure`) — check it, but do not treat it as the FM's result. Note: `RECEIVE` (and any interruption while waiting) triggers an **implicit DB commit** in the caller (exceptions: update tasks) — it also closes the caller's open DB cursors.
- **[info]** Non-blocking alternative for many tasks: `CALL FUNCTION ... STARTING NEW TASK name CALLING cb ON END OF TASK`. The callback receives only the task name (`IMPORTING p_task`); fetch the result **inside** the callback with `RECEIVE RESULTS FROM FUNCTION func IMPORTING ... EXCEPTIONS ...` — never from `sy-subrc` after the `CALL`. Results are buffered in an internal table keyed by task name; failures collected for retry. (`SET HANDLER ... FOR EVENT ... OF` is the unrelated ABAP class-event mechanism, not the RFC callback.)
- **[P1]** Without `WAIT UNTIL`/`RECEIVE` (or the `ON END OF TASK` callback firing), accessing a parallel task's result is a race: you read before completion. Always synchronize before reading the result. <!-- rule: synchronize-before-read -->
- **[P2]** Limit the number of tasks, not one per row: split the input into N chunks by key (RANGE), N proportional to the available work processes. A task per record — worse than sequential.
- **[P3]** For data-parallel loops prefer `cl_abap_parallel` over manual `STARTING NEW TASK`; manual — when you need fine-grained control of tasks.
  ```abap
  " task class: subclass cl_abap_parallel (concrete, not abstract), redefine DO
  CLASS zcl_x_task DEFINITION INHERITING FROM cl_abap_parallel.
    PUBLIC SECTION.
      METHODS do REDEFINITION.
  ENDCLASS.

  CLASS zcl_x_task IMPLEMENTATION.
    METHOD do.
      IMPORT task = lv_task FROM DATA BUFFER p_in.
      " ... compute ...
      EXPORT task = lv_task TO DATA BUFFER p_out.
    ENDMETHOD.
  ENDCLASS.

  " launch: serialize each input item to xstring, one row per task
  DATA(lt_in) = VALUE cl_abap_parallel=>t_in_tab( FOR <ls> IN lt_items ( lcl=>serialize( <ls> ) ) ).
  DATA(lo_par) = NEW zcl_x_task( p_num_tasks = 4 ).
  lo_par->run( EXPORTING p_in_tab = lt_in IMPORTING p_out_tab = DATA(lt_out) ).
  ```
  `p_in_tab` — a table of `xstring` (`EXPORT ... TO DATA BUFFER`); each row of `p_out_tab` carries `RESULT` (xstring → `IMPORT ... FROM DATA BUFFER`), `INDEX`, `TIME`, `MESSAGE` (error/timeout text). Constructor params: `p_num_tasks`/`p_timeout`/`p_percentage`/`p_num_processes` (also `p_local_server`/`p_abort_on_error` — verify the full signature in SE24). `cl_abap_parallel` is a **concrete** class — subclass it and redefine `DO`. In 7.50 the serialized `run( )` above is the API; `run_inst( p_in_tab = ... )` (object-based variant) and `IF_ABAP_PARALLEL` — from 7.54, NOT in 7.50 (see `style.md`, "Version"). There is no `get_instance`. Verify signatures in SE24.
- **[P1]** LUW: each RFC task — its own LUW. `COMMIT` inside a task commits only it; for **aRFC** tasks the caller's `COMMIT` does NOT commit their changes. Function modules registered as **tRFC/qRFC/bgRFC** in the caller's LUW, however, start exactly with the caller's `COMMIT WORK`. For mass loading in chunks, each chunk must be self-consistent (see "Error handling": COMMIT in chunks, broken LUW). <!-- rule: each-task-own-luw -->
- **[info]** bgRFC (transactional/queued) — guaranteed exactly-once delivery within the LUW. The class API — below, section "bgRFC".
- **[P2]** Writing to the same tables from several tasks — ENQUEUE collisions: split by key so tasks do not touch the same rows; otherwise expect and handle `foreign_lock` (see "Error handling").
- **[P2]** A task's errors are not propagated as an exception to the caller (RFC predefined exceptions, see `integration.md`): catch inside the task and return a status/`et_return` — check it for each task, do not treat completion as success.
- **[info]** Background jobs: `JOB_OPEN`/`JOB_SUBMIT`/`JOB_CLOSE` (or `SUBMIT ... VIA JOB ... AND RETURN`). For asynchronous deferred work; the job runs on a **background** work process — NOT for parallelizing inside dialog (it does not use dialog work processes at all).

# bgRFC

> Class API. Outbound destinations are configured in SBGRFCCONF (name types `bgrfc_dest_name_outbound`/`bgrfc_dest_name_inbound`). The payload destination comes from the **unit**, not from a `DESTINATION` clause on `CALL FUNCTION`.
- **[info]** Outbound destination: `cl_bgrfc_destination_outbound=>create( dest_name = ... )` → `IF_BGRFC_DESTINATION_OUTBOUND` (raises `CX_BGRFC_INVALID_DESTINATION`). From it: `create_trfc_unit( )` → `IF_TRFC_UNIT_OUTBOUND` (raises `CX_BGRFC_INVALID_DESTINATION`); `create_qrfc_unit( )` → `IF_QRFC_UNIT_OUTBOUND` (raises `CX_BGRFC_INVALID_CONTEXT`); `create_qrfc_unit_outinbound( )` → `IF_QRFC_UNIT_OUTINBOUND` (raises `CX_BGRFC_INVALID_CONTEXT`) — a queued round-trip (send + get a queued response back).
- **[info]** Inbound (receiving side): `cl_bgrfc_destination_inbound=>create( dest_name = ... )` → `IF_BGRFC_DESTINATION_INBOUND` (raises `CX_BGRFC_INVALID_DESTINATION`); its `create_trfc_unit( )`/`create_qrfc_unit( )` raise `CX_BGRFC_INVALID_CONTEXT`.
- **[info]** qRFC queue (FIFO per queue): `lo_unit->add_queue_name_outbound( queue_name = ... ignore_duplicates = abap_false )`; plural `add_queue_names_outbound( queue_names = ... )`; inbound analog `add_queue_name_inbound( ... )`. These raise `CX_BGRFC_INVALID_UNIT`, `CX_QRFC_INVALID_QUEUE_NAME`, `CX_QRFC_DUPLICATE_QUEUE_NAME`.
- **[info]** Registering a call: `CALL FUNCTION 'Z_FM' IN BACKGROUND UNIT lo_unit EXPORTING ...` — the payload FM is put into the unit object, not executed immediately (no `DESTINATION` clause — the unit carries it). The payload FM must be remote-enabled (RFC) in SE37.
- **[info]** Common `IF_BGRFC_UNIT` members (both t/q, in/outbound): attribute `unit_id`; methods `get_function_count( )`/`get_function_call_list( )`, `set_function_call_order( permutation )` (reorder calls inside the unit; raises `CX_BGRFC_ILLEGAL_PERMUTATION`, `CX_BGRFC_INVALID_UNIT`), `delay( seconds )` (execute after N seconds; raises `CX_BGRFC_INVALID_UNIT`, `CX_BGRFC_INVALID_TIME_SPEC`), `lock( )` → `LOCK_ID` (raises `CX_BGRFC_INVALID_UNIT`), `separate_from_update_task( )` (own LUW, not the update task; raises `CX_BGRFC_INVALID_UNIT`), `is_valid( )`, `disable_commit_checks( )`, `free( )`. (There is no `priority` attribute on `IF_BGRFC_UNIT`.) `create_unit_by_pattern( )` is declared on the specific unit interfaces (`IF_TRFC_UNIT_OUTBOUND`, `IF_QRFC_UNIT_*`) — clone the payload into another unit (mass parallel without re-serializing); verify the exact interface in SE24.
- **[P1]** The unit executes exactly once after `COMMIT WORK` of the creating LUW. No `COMMIT` — the unit does not start (transactional). An abort/ROLLBACK of the creating LUW cancels the unit. <!-- rule: unit-runs-after-commit -->
- **[P2]** `lo_unit->if_bgrfc_unit~disable_commit_checks( )` — disables the **transactional consistency check** of a bgRFC unit, i.e. the check that would abort on commit-capable statements *inside* the unit (sRFC/aRFC, `WAIT`, `COMMIT WORK`/`ROLLBACK WORK`, HTTP, `DB_COMMIT`). Call it **only** after analyzing the SAP LUW of the generated unit and the repeated-execution case: SAP does not guarantee the transactional integrity of a unit whose checks were disabled — a unit that partially committed and then terminates can, on re-execution, write data more than once. It is **not** a "unit registered but not committed" control and not a substitute for an explicit `COMMIT` of the creating LUW.
- **[P2]** Catch the concrete exception each call raises (map above), wrap in your own `zcx_*` (see "Error handling"): `cx_bgrfc_invalid_destination`, `cx_bgrfc_invalid_context`, `cx_bgrfc_invalid_unit`, `cx_bgrfc_invalid_time_spec`, `cx_bgrfc_illegal_permutation`; queue — `cx_qrfc_invalid_queue_name`, `cx_qrfc_duplicate_queue_name`.
- **[info]** Error monitoring: `cl_bgrfc_monitor_api` (package `sbgrfcmon`) — `create_bgrfc_monitor_inbound/outbound( )` → `IF_BGRFC_MONITOR_INBOUND`/`IF_BGRFC_MONITOR_OUTBOUND`; `create_trfc_monitor_inbound/outbound( )` → `IF_TRFC_INBOUND_MONITOR`/`IF_TRFC_OUTBOUND_MONITOR`; `create_qrfc_monitor_inbound/outbound( )` → `IF_QRFC_INBOUND_MONITOR`/`IF_QRFC_OUTBOUND_MONITOR`; `create_utility( )` → `IF_BGRFC_MONITOR_API_UTILITY` (message helpers). Note the asymmetric interface names — `IF_TRFC_INBOUND_MONITOR`, **not** `IF_TRFC_MONITOR_INBOUND`. Read stuck/failed units here, not in the caller's `sy-subrc`.
