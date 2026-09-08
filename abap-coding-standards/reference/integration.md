# Integration: BDC, memory, BAdI, RFC/HTTP

## Batch input / CALL TRANSACTION (BDC)

- **[P2]** Loading via a transaction — `CALL TRANSACTION <tcode> USING lt_bdcdata OPTIONS FROM ls_ctu_params MESSAGES INTO lt_msg`. `MESSAGES INTO` (table `bdcmsgcoll`) is mandatory: without it, transaction errors are silently lost. Determine success not by `sy-subrc` alone (reliable: `0` = success, `< 1000` = error, e.g. `1001` = not executed — not a success marker) but by the absence of `msgtyp = 'E'`/`'A'` in `lt_msg` (or by the transaction's success message). Field is `msgtyp`, not `msqtyp`.
- **[P2]** `ctu_params-dismode`: `'N'` — background (no UI), `'E'` — only screens with an error, `'A'` — all. In prod — `'N'`/`'E'`, not `'A'`. `updmode = 'S'` (synchronous) — when the write result matters immediately.
- **[P3]** BDC — the last resort: first a BAPI/class/FM, then `CALL TRANSACTION`; sessions (`BDC_OPEN_GROUP`/`BDC_INSERT`/`BDC_CLOSE` + SM35) — for deferred loading. BDC breaks when screens/screen variants change.
- **[info]** The message text from `bdcmsgcoll` — `MASS_MESSAGE_GET` (by `msgid`/`msgno`/`msgv1..4`); `bdcmsgcoll` stores only ID/number/variables, not text.

## Memory (ABAP / SAP / Shared)

- **[info]** Data scope: ABAP Memory (`EXPORT/IMPORT ... TO/FROM MEMORY ID`) — a window (external session) + its internal sessions; SAP Memory (`SET/GET PARAMETER`) — the whole user session, but only flat `c`/`n`/`d`/`t`; `SHARED BUFFER`/`SHARED MEMORY` — all users/clients of one application server, not persistent (lost on restart); `TO DATABASE` (cluster `INDX`) — persistent.
- **[P2]** `SHARED BUFFER`/`SHARED MEMORY` — a cache of recoverable data, not a source of truth: a record can be evicted (SHARED BUFFER — automatically by LRU) or lost on restart. Do not rely on presence on read; after use — `DELETE FROM`.
- **[P3]** For explicit sharing between sessions prefer shared objects (`AREA HANDLE`) over `SHARED BUFFER`/`SHARED MEMORY` — the lifecycle and locks are manageable. (State does not cross the task boundary — see `parallel.md`.)
- **[P2]** Access shared data (`SHARED MEMORY`/`SHARED BUFFER`, shared objects, class-static buffers) only through a **data-access class** (get/set methods wrapping the shared area): one access point, a where-used list on every shared-data usage, and a mockable seam for tests. Do not touch the shared area directly from business code.

## BAdI (enhancement framework)

- **[P3]** The new (kernel) BAdI syntax — `GET BADI lo_badi FILTERS filter = lv_value` (no `sy-subrc` from `GET BADI` — handle `cx_badi_not_implemented`/`cx_badi_multiple_implementations` instead) + `CALL BADI lo_badi->method( )`; cleaner than the classic `GET BADI` with a proxy object. For new points — only the new syntax.
- **[P2]** Extension point: first a ready BAdI/customer exit; none — an explicit enhancement (source/function/class); an implicit enhancement — last. Do not modify SAP code directly — only via the enhancement mechanism.

## BOPF

- **[info]** BOPF (Business Object Processing Framework; Fiori/transactional apps on NetWeaver) owns the business data via its API. Do not read/write BOPF tables directly — only through the framework (node instances, `retrieve_by_association`, the modify + determination/validation/action stack): direct DB access bypasses the buffer and the model logic. Verify the BOPF scope in SE24 (`IF_BOPF_*`) on the target system before relying on it.

## Remote communication (RFC / HTTP)

- **[info]** RFC interface contract of a remote-enabled FM (ABAPDocu "RFC Restrictions"): IMPORTING/EXPORTING/CHANGING parameters are passed **by value**, TABLES implicitly by value; parameter types must be DDIC or predefined ABAP types (no local type-group types, no reference types). Because of pass-by-value there is no access to the caller's intermediate results during a synchronous RFC — the FM must return everything in its results (TABLES are the exception).
- **[P1]** Every synchronous and asynchronous RFC call performs a **database commit** — do not place sRFC/aRFC between Open SQL statements that open or close a DB cursor (a cursor SELECT loop plus an RFC inside would close the cursor). Exceptions: update tasks, where the RFC does not trigger a commit.
- **[P1]** In transactional RFC (tRFC/qRFC/bgRFC): `COMMIT WORK` and `ROLLBACK WORK` must **not** be executed inside a unit/LUW, and no implicit database commit can be triggered there.
- **[P2]** In a remotely called FM, do not execute statements that close the RFC session/connection: `LEAVE PROGRAM`, `SUBMIT` without `RETURN`.
- **[P1]** The RFC interface supports only **classic** exceptions — a class-based exception raised in the remote FM is not transported and becomes the predefined classic `SYSTEM_FAILURE`. Handle the predefined exceptions (`SYSTEM_FAILURE`, `COMMUNICATION_FAILURE`, and `RESOURCE_FAILURE` with pRFC): ABAPDocu "RFC Exceptions" strongly recommends handling all of them — an unhandled communication failure breaks the chain silently.
- **[P2]** Destinations: static destinations are configured in SM59; dynamic destinations are created via `cl_dynamic_destination` and get the `%%` prefix — such destinations "must never be added to programs from external sources" (ABAPDocu "RFC Destination"). Do not build a destination from unchecked external input; validate/whitelist the destination name.
- **[info]** Trusted-system RFC logon requires the RFC authorization (S_RFCACL); anonymous logon is only allowed for system function modules; the privileged users `DDIC`/`SAP*` cannot be used as anonymous RFC logon users (ABAPDocu `CALL FUNCTION - RFC`, logon error codes).
- **[P3]** bgRFC instead of tRFC for new transactional calls — ABAPDocu `CALL FUNCTION - RFC`: "Background RFC (bgRFC) is the enhanced successor technology of transactional RFC (tRFC)... strongly recommended that bgRFC be used instead of tRFC." (bgRFC mechanics — `parallel.md`.)
- **[info]** ABAP as an HTTP client — `cl_http_client=>create( host = ... service = ... )`, then `send`/`receive` with a `sy-subrc` check after each and `get_last_error` for diagnostics, `close` at the end; the proxy must be configured in SICF (ABAPDocu "ABAP as HTTP Client"). HTTPS/TLS specifics depend on the SSL client configuration of the server — verify on the target system.

## Transport release (review gate)

- **[info]** A transport release can be vetoed from code via the BAdI `CTS_REQUEST_CHECK` (method `CHECK_BEFORE_RELEASE`) — e.g. require the code review / CI result before release, or run ATC/ABAP Unit programmatically at release time.
