# Integration: BDC, memory, BAdI, RFC/HTTP

## Batch input / CALL TRANSACTION (BDC)

- **[P2]** Loading via a transaction — `CALL TRANSACTION <tcode> USING lt_bdcdata OPTIONS FROM ls_ctu_params MESSAGES INTO lt_msg`. `MESSAGES INTO` (table `bdcmsgcoll`) is mandatory: without it, transaction errors are silently lost. Determine success not by `sy-subrc` alone (reliable: `0` = success, `< 1000` = error, e.g. `1001` = not executed — not a success marker) but by the absence of `msgtyp = 'E'`/`'A'` in `lt_msg` (or by the transaction's success message). Field is `msgtyp`, not `msqtyp`.
- **[P2]** `ctu_params-dismode`: `'N'` — background (no UI), `'E'` — only screens with an error, `'A'` — all. In prod — `'N'`/`'E'`, not `'A'`. `updmode = 'S'` (synchronous) — when the write result matters immediately. `nobinpt = 'X'` — switch off batch-input processing (common in mass runs).
- **[P3]** BDC — the last resort: first a BAPI/class/FM, then `CALL TRANSACTION`; sessions (`BDC_OPEN_GROUP`/`BDC_INSERT`/`BDC_CLOSE` + SM35) — for deferred loading. BDC breaks when screens/screen variants change.
- **[info]** The message text from `bdcmsgcoll` — `MASS_MESSAGE_GET` (by `msgid`/`msgno`/`msgv1..4`); `bdcmsgcoll` stores only ID/number/variables, not text.

## Memory (ABAP / SAP / Shared)

- **[info]** Data scope: ABAP Memory (`EXPORT/IMPORT ... TO/FROM MEMORY ID`) — a window (external session) + its internal sessions; SAP Memory (`SET/GET PARAMETER`) — the whole user session, but only flat `c`/`n`/`d`/`t`; `SHARED BUFFER`/`SHARED MEMORY` — all users/clients of one application server, not persistent (lost on restart); `TO DATABASE` (cluster `INDX`) — persistent.
- **[P2]** `SHARED BUFFER`/`SHARED MEMORY` — a cache of recoverable data, not a source of truth: a record can be evicted (SHARED BUFFER — automatically by LRU) or lost on restart. Do not rely on presence on read; after use — `DELETE FROM`.
- **[P3]** For explicit sharing between sessions prefer shared objects (`AREA HANDLE`) over `SHARED BUFFER`/`SHARED MEMORY` — the lifecycle and locks are manageable. (State does not cross the task boundary — see `parallel.md`.)
- **[P2]** Access shared data (`SHARED MEMORY`/`SHARED BUFFER`, shared objects, class-static buffers) only through a **data-access class** (get/set methods wrapping the shared area): one access point, a where-used list on every shared-data usage, and a mockable seam for tests. Do not touch the shared area directly from business code.

## BAdI (enhancement framework)

- **[P3]** The new (kernel) BAdI syntax — `GET BADI lo_badi FILTERS filter = lv_value` (no `sy-subrc` from `GET BADI` — handle the class-based exceptions instead: `cx_badi_not_implemented`/`cx_badi_multiply_implemented`; there is no `cx_badi_multiple_implementations`) + `CALL BADI lo_badi->method( )`; cleaner than the classic `GET BADI` with a proxy object. For new points — only the new syntax.
- **[info]** BAdI **definition** (SE18): the fallback when no active implementation exists is `DEFAULT IGNORE` or `DEFAULT FAIL` in the definition — `DEFAULT FAIL` raises an error for an unimplemented BAdI, `DEFAULT IGNORE` silently does nothing; choose deliberately.
- **[P2]** Extension point: first a ready BAdI/customer exit; none — an explicit enhancement (source/function/class); an implicit enhancement — last. Do not modify SAP code directly — only via the enhancement mechanism.

## BOPF

- **[info]** BOPF (Business Object Processing Framework; Fiori/transactional apps on NetWeaver) owns the business data via its API. Do not read/write BOPF tables directly — only through the framework (node instances, `retrieve_by_association`, the modify + determination/validation/action stack): direct DB access bypasses the buffer and the model logic. Verify the BOPF scope in SE24 (`IF_BOPF_*`) on the target system before relying on it.

## Remote communication (RFC / HTTP)

- **[info]** RFC interface contract of a remote-enabled FM (ABAPDocu "RFC Restrictions"): IMPORTING/EXPORTING/CHANGING parameters are passed **by value**, TABLES implicitly by value; parameter types must be DDIC or predefined ABAP types (no local type-group types, no reference types). Because of pass-by-value there is no access to the caller's intermediate results during a synchronous RFC — the FM must return everything in its results (TABLES are the exception).
- **[P1]** Every synchronous and asynchronous RFC call performs a **database commit** — do not place sRFC/aRFC between Open SQL statements that open or close a DB cursor (a cursor SELECT loop plus an RFC inside would close the cursor). Exceptions: update tasks, where the RFC does not trigger a commit. <!-- rule: rfc-performs-commit -->
- **[P1]** In transactional RFC (tRFC/qRFC/bgRFC): `COMMIT WORK` and `ROLLBACK WORK` must **not** be executed inside a unit/LUW, and no implicit database commit can be triggered there. <!-- rule: trfc-no-commit-in-luw -->
- **[P2]** In a remotely called FM, do not execute statements that close the RFC session/connection: `LEAVE PROGRAM`, `SUBMIT` without `RETURN`.
- **[P2]** The RFC interface supports only **classic** exceptions — a class-based exception raised in the remote FM is not transported and becomes the predefined classic `SYSTEM_FAILURE`. Handle the predefined exceptions (`SYSTEM_FAILURE`, `COMMUNICATION_FAILURE`, and `RESOURCE_FAILURE` with pRFC): ABAPDocu "RFC Exceptions" strongly recommends handling all of them — an unhandled communication failure breaks the chain silently.
- **[P2]** Destinations: static destinations are configured in SM59; dynamic destinations are created via `cl_dynamic_destination` and get the `%%` prefix — such destinations "must never be added to programs from external sources" (ABAPDocu "RFC Destination"). Do not build a destination from unchecked external input; validate/whitelist the destination name.
- **[info]** Trusted-system RFC logon requires the RFC authorization (S_RFCACL); anonymous logon is only allowed for system function modules; the privileged users `DDIC`/`SAP*` cannot be used as anonymous RFC logon users (ABAPDocu `CALL FUNCTION - RFC`, logon error codes).
- **[P3]** bgRFC instead of tRFC for new transactional calls — ABAPDocu `CALL FUNCTION - RFC`: "Background RFC (bgRFC) is the enhanced successor technology of transactional RFC (tRFC)... strongly recommended that bgRFC be used instead of tRFC." (bgRFC mechanics — `parallel.md`.)
- **[info]** ABAP as an HTTP client — create via `cl_http_client=>create_by_url( url = ... )` (the base form; the raw `create( host = ... service = ... )` is essentially unused in practice). Reusable connections with SSL/auth/proxy configured in SM59 — `create_by_destination( destination = ... )`. TLS relies on the SM59 destination's SSL or the default SSL client — no SSL is set in code (`ssl_id` unused).
- **[P2]** Request setup: `request->set_method( if_http_request=>co_request_method_post )` (or GET), `set_header_field( name = ... value = ... )`, `set_content_type( 'application/json' )`, body via `set_cdata( lv_string )` (text) or `set_data( lv_xstring )` (binary); the path — `cl_http_utility=>set_request_uri( request = ... uri = ... )`.
- **[P2]** Auth: basic — `client->authenticate( username = ... password = ... )` **and** `client->propertytype_logon_popup = if_http_client=>co_disabled` (suppress the SAP logon popup); token — `request->set_header_field( name = 'Authorization' value = |Bearer { lv_token }| )`.
- **[P1]** Send/receive — check both: `client->send( EXCEPTIONS OTHERS = 1 )` then `IF sy-subrc <> 0`; same for `receive( )`. `EXCEPTIONS OTHERS = 0` on `send` **disables** error detection (`sy-subrc` 0 on failure) — a silent-failure anti-pattern. Surface via `client->get_last_error( IMPORTING message = lv_msg )`. <!-- rule: http-check-send-receive -->
- **[P2]** Response status — `response->get_status( IMPORTING code = lv_code )`, then `cl_rest_status_code=>is_error( lv_code )`/`is_success( lv_code )` (or `lv_code BETWEEN 200 AND 299`); do not compare `= 200` (breaks on 201/204). Read the body via `response->get_cdata( )` (string) / `get_data( )` (xstring, then `cl_abap_conv_in_ce` with `i_encoding = 'UTF-8'`).
- **[P2]** `client->close( )` on the normal path **and** in a `CLEANUP` block; before re-sending on a long-lived client — `refresh_request( )`/`refresh_response( )`. A missing `close` leaks the connection.

## Transport release (review gate)

- **[info]** A transport release can be vetoed from code via the BAdI `CTS_REQUEST_CHECK` (method `CHECK_BEFORE_RELEASE`) — e.g. require the code review / CI result before release, or run ATC/ABAP Unit programmatically at release time.
