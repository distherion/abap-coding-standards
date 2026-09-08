# Integration: BDC, memory, BAdI

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

## Transport release (review gate)

- **[info]** A transport release can be vetoed from code via the BAdI `CTS_REQUEST_CHECK` (method `CHECK_BEFORE_RELEASE`) — e.g. require the code review / CI result before release, or run ATC/ABAP Unit programmatically at release time.
