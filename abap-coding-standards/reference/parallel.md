# Parallelism and background processes

- **[P2]** Parallel — only for data-independent chunks: mass load/calculation where rows do not affect each other. Order is not guaranteed; do not pass shared counters/flags via shared state.
- **[P1]** State does not cross the task boundary: each parallel task (RFC task, background job) — its own work process/session. ABAP memory (`EXPORT/IMPORT ... MEMORY ID`), `SET/GET PARAMETER`, class statics — NOT visible to the caller in parallel (see "Classes": static ≠ request state). Session state — only via call parameters/result.
- **[P2]** Launch: `CALL FUNCTION ... STARTING NEW TASK taskname`, on completion — `WAIT UNTIL` / `RECEIVE RESULTS FROM FUNCTION`. Take the result via `RECEIVE`, not via the caller's `sy-subrc`/`sy-msgid` — RFC does not set them. Note: `RECEIVE` (and any interruption while waiting) triggers an **implicit DB commit** in the caller (exceptions: update tasks) — it also closes the caller's open DB cursors.
- **[P1]** Without `WAIT UNTIL`/`RECEIVE`, accessing a parallel task's result is a race: you read before completion. Always synchronize before reading the result.
- **[P2]** Limit the number of tasks, not one per row: split the input into N chunks by key (RANGE), N proportional to the available work processes. A task per record — worse than sequential.
- **[P3]** For data-parallel loops prefer `cl_abap_parallel` (7.40+, callback) over manual `STARTING NEW TASK`; manual — when you need fine-grained control of tasks.
  ```abap
  DATA(lo_par) = cl_abap_parallel=>get_instance( ).
  lo_par->run_inst( it_in = lt_items
                    io_parallel_task = NEW zcl_x_task( ) ).
  ```
  `zcl_x_task` implements `IF_ABAP_PARALLEL` (method `DO` — processing one `is_item`); take the result via the callback class's `EXPORTING` table. Verify the exact `run_inst`/`DO` signature in SE24 (`CL_ABAP_PARALLEL`/`IF_ABAP_PARALLEL`).
- **[P1]** LUW: each RFC task — its own LUW. `COMMIT` inside a task commits only it; the caller's `COMMIT` does NOT commit RFC changes (unless bgRFC). For mass loading in chunks, each chunk must be self-consistent (see "Error handling": COMMIT in chunks, broken LUW).
- **[info]** bgRFC (transactional/queued) — guaranteed exactly-once delivery within the LUW. The class API — below, section "bgRFC".
- **[P2]** Writing to the same tables from several tasks — ENQUEUE collisions: split by key so tasks do not touch the same rows; otherwise expect and handle `foreign_lock` (see "Error handling").
- **[P2]** A task's errors are not propagated as an exception to the caller (RFC predefined exceptions, see `integration.md`): catch inside the task and return a status/`et_return` — check it for each task, do not treat completion as success.
- **[info]** Background jobs: `JOB_OPEN`/`JOB_SUBMIT`/`JOB_CLOSE` (or `SUBMIT ... VIA JOB ... AND RETURN`). For asynchronous deferred work; the job runs on a **background** work process — NOT for parallelizing inside dialog (it does not use dialog work processes at all).

# bgRFC

> Class API. Destinations are configured in SBGRFCCONF (name — type `bgrfc_dest_name_outbound`/`bgrfc_dest_name_inbound`).
- **[info]** Destination + unit: outbound/tRFC — `cl_bgrfc_destination_outbound=>create( dest_name = ... )->create_trfc_unit( )`; queued/qRFC (order) — `cl_bgrfc_destination_inbound=>create( dest_name = ... )->create_qrfc_unit( )` + `lo_unit->add_queue_name_inbound( queue_name = ... )` (FIFO inside a queue).
- **[info]** Registering a call: `CALL FUNCTION 'Z_FM' IN BACKGROUND UNIT lo_unit EXPORTING ...` — the payload FM is put into the unit object, not executed immediately.
- **[P1]** The unit executes exactly once after `COMMIT WORK` of the creating LUW. No `COMMIT` — the unit does not start (transactional). An abort/ROLLBACK of the creating LUW cancels the unit.
- **[P2]** `lo_unit->if_bgrfc_unit~disable_commit_checks( )` — allow a unit without an explicit `COMMIT` (when the caller decides/defers the commit itself). Otherwise the framework requires a commit check.
- **[P2]** Catch destination/unit exceptions: `cx_bgrfc_invalid_destination`, `cx_bgrfc_invalid_context`, `cx_bgrfc_invalid_unit`; for a queue — `cx_qrfc_invalid_queue_name`, `cx_qrfc_duplicate_queue_name`. Wrap in your own `zcx_*` (see "Error handling").
- **[info]** Error monitoring: `cl_bgrfc_monitor_api=>create_qrfc_monitor_inbound( )` returns a monitor object (`IF_QRFC_MONITOR_INBOUND`) with methods to read failed/stuck queues (tRFC — `create_trfc_monitor_*`). Verify exact method names in SE24 by `IF_QRFC_MONITOR_INBOUND` — do not write from memory. Look at stuck/failed units here, not in the caller's `sy-subrc`.
