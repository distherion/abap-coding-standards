# Security

- **[P2]** Dynamic SQL — only when static is impossible. Never concatenate external input (UI fields, RFC parameters, files) into a SQL string. Hierarchy: static Open SQL → binding `?` + `USING` → `CL_ABAP_DYN_PRG` (`quote`/`quote_str`/`escape_quotes`/`check_table_name_str`/`check_whitelist_str`). ADBC — only `?` + `SET_PARAM`.
- **[P1]** Dynamic names/tokens (`(tabname)`, `(colname)`, `ASSIGN (lv)`, `CALL FUNCTION (lv)`, `(lv_comp)-field`) and dynamic `WHERE`/`HAVING` — the name source is not external (UI/RFC/file), validate against a whitelist; handle `cx_sy_dynamic_osql_syntax`/`cx_abap_dyn_prg_illegal_value`/`cx_sql_exception`.
- **[P1]** `HR_READ_INFOTYPE_AUTHC_DISABLE` disables the P_ORGIN check for `HR_READ_INFOTYPE`; there is **no** standard `..._AUTHC_ENABLE` (per docs DISABLE is "for one read", but opinions on persistence in the work process differ). Call DISABLE immediately before the read that needs the bypass (you already checked authorization yourself — `HR_CHECK_AUTHORITY_INFTY`/PNP), and do not leave it hanging before a series of `HR_READ_INFOTYPE`. There is no stable off/on for PA. `RH_AUTHORITY_CHECK_OFF`/`RH_AUTHORITY_CHECK_ON` — NOT about PA: that is structural authorization (OM/PD objects via `RH_*` FMs, OOSP/OOSB), unrelated to `P_ORGIN`/PA infotypes.
- **[P2]** Reading and writing HR infotypes — via standard HR mechanisms (`HR_READ_INFOTYPE`, `HR_INFOTYPE_OPERATION`, `HR_MAINTAIN_MASTERDATA`; class-based reader `cl_hrpa_read_infotype`/`if_hrpa_read_infotype`, `read_single`; in LDB-PNP the numbers are filtered by the LDB itself) — SAP checks **P_ORGIN** itself, a separate `AUTHORITY-CHECK` is not needed. `P_PERNR` ("own" pernr) is not covered by this — a separate object, enabled by the OOAC switch.
- **[P2]** Direct Open SQL to HR tables (`pa0001`…) bypasses the auto-check — check authorization manually for both read and write (`HR_CHECK_AUTHORITY_INFTY`). Bypassing the auto-check at the API — only where you checked authorization yourself: FM `HR_READ_INFOTYPE_AUTHC_DISABLE` (nuances — above); class-based reader — `no_auth_check = abap_true` at `if_hrpa_read_infotype~read_*`.
- **[P1]** `AUTHORITY-CHECK` — for the action and before data access (only transaction/report/RFC/`S_TABU_DIS` are auto-checked; cover internal actions yourself). `sy-subrc = 0` is not a guarantee of rights (an object may have no-check mode) — check the actual field; `4/12` — no rights: abort with a message, do not continue.
- **[P2]** Do not modify standard SAP tables directly (`INSERT`/`UPDATE`/`DELETE`) — only via BAPI/API/classes. A direct write breaks invariants and does not survive an upgrade. You may modify your own `Z`-tables.
- **[P1]** `CALL 'C-function'` (kernel call) is forbidden — bypasses all checks, a direct call into the C kernel. Do not use.
- **[P2]** `CALL TRANSACTION ... WITHOUT AUTHORITY-CHECK` — only after an explicit `AUTHORITY-CHECK`; bypassing the auto-check on external input — P0.

# Output and encoding (XSS)

- **[P2]** Output of external data into HTML/XML/JS/URL/CSS — encode it: `cl_abap_dyn_prg=>escape_xss_xml_html( val )` / `escape_xss_javascript` / `escape_xss_url` / `escape_xss_css` (7.50). Built-in `escape( val = ... format = cl_abap_format=>e_xss_ml )` — from 7.53 (see `style.md`). WebDynpro/BSP encode themselves — do not duplicate manually.

# Dynamic files, code and OS commands

- **[P1]** A file name/path from external input in `OPEN DATASET`/`DELETE DATASET` — path traversal. Do not concatenate external input into a path: logical names via `FILE_GET_NAME`, or validation `FILE_VALIDATE_NAME( logical_filename = ... )` (requires a logical name, only absolute paths); otherwise manual filtering of `../`/`..\` + a whitelist of extensions/directory.
- **[P0]** Dynamic generation/loading of code with external content — `GENERATE SUBROUTINE POOL`, `INSERT REPORT`, `READ REPORT`, `SYNTAX-CHECK` — arbitrary code execution (= `SAP_ALL`). Do not use for external input; instead of `INSERT REPORT` from text — a static report.
- **[P0]** Executing OS commands: `CALL 'SYSTEM'`, `OPEN DATASET ... FILTER`, `cl_gui_frontend_services=>execute` — command injection, unsafe even without external input. For external commands — only SXPG (`SXPG_CALL_SYSTEM` with a logical command name). `CALL 'SYSTEM'` is silenced by profile `rdisp/call_system`.

# RFC and trusted systems

- **[P2]** `CALL FUNCTION ... DESTINATION`: the target system checks `S_RFC` (fields `RFC_NAME`/`ACTVT`/`RFC_TYPE`); for an explicit check before the call — `AUTHORITY_CHECK_RFC` (catch `RFC_NO_AUTHORITY`/`USER_DONT_EXIST`). In destinations — a dedicated communication user, not `DDIC`/`SAP*`; trusted connections (`SMT1`) are additionally controlled by `S_RFCACL`.
