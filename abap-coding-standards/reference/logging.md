# Logging

> Accumulate messages via the standard `cl_reca_message_list` → show → persist into the Application Log (SLG1).
- **[info]** `cl_reca_message_list` — a wrapper over the Application Log (SLG1). If the class is unavailable (not an RE-FX system) — the same mechanics via the standard BAL API: `BAL_LOG_CREATE`/`BAL_LOG_MSG_ADD`/`BAL_DB_SAVE`/`BAL_DSP_LOG_DISPLAY`, or the wrapper class `cl_bd_appl_log`. The principles (accumulate messages, do not stop on the first, show at the end) are the same.
- **[info]** Instance: `DATA(lo_msglist) = NEW cl_reca_message_list( ).` Optionally `init( id_object = ... id_subobject = ... )` sets the SLG1 object/subobject. One per process — pass via parameters/DI; do not create your own Z-subclass or a singleton without need.
- **[P2]** A message into the log, not the UI: `MESSAGE eNNN WITH ... INTO DATA(lv_dummy)` (class/number as literals, see "Error handling") then `lo_msglist->add_symsg( ).` `add_symsg` picks up `sy-msgid/sy-msgty/sy-msgno/sy-msgv1..4` of the last `MESSAGE`.
- **[P2]** Direct add (without `MESSAGE INTO`, e.g. in `CATCH`): `lo_msglist->add( is_message = VALUE #( msgty = sy-msgty msgid = sy-msgid msgno = sy-msgno msgv1 = sy-msgv1 ... ) ).`
- **[P2]** Accumulate messages, do not stop on the first: accumulate in a loop, show at the end. Presence of a needed type: `lo_msglist->has_message( id_msgty = 'E' )`; the list is **empty** — `is_empty( ) = abap_true` (i.e. `is_empty( ) = abap_false` means there are messages — do not confuse the labels).
- **[P2]** Binding to a row/field — via `id_tabname`/`id_fieldname`/`id_context` on `add_symsg`/`add`; check — `has_message( it_cfil = ... )`.
- **[P3]** Show: `lo_msglist->display( iv_popup = abap_false )` (or `id_handle = lo_msglist->get_handle( )`). Save into the Application Log: `lo_msglist->store( if_in_update_task = abap_false )` (in the update task — `abap_true`).
- **[P2]** `lo_msglist->clear( )` before a new chunk/pass — otherwise messages of the previous iteration stick and duplicate.
- **[P1]** `CATCH cx_reca_symsg` / `cx_sy_msg` — add to the log, do not swallow silently and do not pass off as success (see "Error handling": an empty `CATCH` is forbidden).
- **[info]** Show the accumulated Application Log by handle: `cl_log_ppf=>show_log( lo_msglist->get_handle( ) )`.
- **[P2]** Mass processing (a loop over many rows/objects) — do not write a log entry per iteration: accumulate and add via `add`/`add_symsg` once per chunk or per aggregate — `cl_reca_message_list` and the Application Log (SLG1) cost memory and slow the run.
