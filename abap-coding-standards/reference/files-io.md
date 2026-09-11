# File input/output in ABAP

- **[P3]** A file on the application server: `OPEN DATASET lv_file FOR INPUT/OUTPUT/APPENDING IN TEXT MODE ENCODING UTF-8` → `TRANSFER`/`READ DATASET` → `CLOSE DATASET`; binary — `IN BINARY MODE` (without `IN TEXT MODE`). The path — a **physical** name (an absolute path is allowed); a logical file name must first be resolved via `FILE_GET_NAME`/transaction `FILE` — AL11 only shows server directories, it is not the logical-name catalog.
- **[P2]** A file on the presentation server (frontend): `cl_gui_frontend_services=>gui_upload`/`gui_download`; large files — `gui_download` with `filetype = 'BIN'`/`'ASC'`. These methods are classic **FM with `EXCEPTIONS`** (`file_open_error`, `file_read_error`, `no_batch`, `error_no_gui`, `cntl_error`, …) — check `sy-subrc` immediately; there is **no** class-based exception for frontend file access — do not expect a class-based `CATCH` here.
- **[P2]** Encodings: reading/writing UTF-8 — explicitly `ENCODING UTF-8`. cp1251↔UTF-8 — `cl_abap_conv_in_ce`/`cl_abap_conv_out_ce` (`CONVERT TEXT ... INTO SORTABLE CODE` does a **sorting-key** conversion, not a codepage/encoding one — do not use it for re-encoding); `xstring`↔`string` — `cl_abap_codepage=>convert_from/convert_to`.
- **[P2]** Do not parse CSV/JSON/XML by hand in a character loop: CSV — `cl_rsda_csv_converter`/a proven splitter; JSON — `/ui2/cl_json`/`cl_trex_json_serializer`; XML/JSON — `CALL TRANSFORMATION id`.
- **[P3]** `CALL TRANSFORMATION id SOURCE data RESULT XML xstr` — serialization/deserialization instead of manual concatenation.
- **[P1]** A size/path from external input — validate it (a whitelist of file names, a size limit), otherwise path traversal/DoS (see `security.md`). <!-- rule: file-path-validate-input -->

# sXML (JSON/XML streaming)

- **[P2]** Generating/editing JSON/XML — sXML streaming (`cl_sxml_string_writer=>create( type = if_sxml=>co_xt_json )` + `read_next_node`/`write_node`), not manual string concatenation. Parsing large payloads — `cl_sxml_string_reader=>create( )` and pass the reader straight into `CALL TRANSFORMATION id SOURCE XML <reader>` (without materializing the string; ST auto-detects JSON).

# Email (CL_BCS_MESSAGE)

- **[P2]** Prefer sending via `cl_bcs_message` (high-level BCS API, since NW 7.40): `NEW cl_bcs_message( )` → `set_subject( )`/`set_main_doc( )`/`add_attachment( )`/`add_recipient( )`/`set_sender( )` → `send( )`. Shorter and cleaner than the low-level chain `cl_bcs` + `cl_document_bcs` + `cl_send_request_bcs` + `cl_cam_address_bcs`. The body is set with `set_main_doc( iv_contents_txt = ... iv_doctype = ... )` (there is no `add_text`); instantiate with `NEW` (no `create_instance`); `send( )` raises `cx_bcs_send`. Verify signatures in SE24, not from memory.
- **[P2]** A persistent BCS send request is persisted (Object Services) and dispatched **at `COMMIT WORK`** — no COMMIT, no send, the request stays unprocessed in SOST. `set_send_immediately( 'X' )` (low-level API) only switches the **send mode** — it does not replace the COMMIT that persists the request. The `COMMIT` belongs to the owner of the business LUW at a consistent point, not to an arbitrary mail helper; catch `cx_bcs_send` and check the send result.
- **[info]** A binary attachment (low-level API): `cl_document_bcs=>xstring_to_solix( ip_xstring = ... )` (the dominant helper is `cl_bcs_convert=>xstring_to_solix( iv_xstring = ... )`) + in `add_attachment( )` pass both `i_att_content_hex` and `i_attachment_size` (the size is a parameter of `cl_document_bcs=>add_attachment` — without it a binary attachment breaks/is empty).

# Excel (.xlsx)

- **[P2]** Do not generate Excel by hand (`gui_download` to CSV, OLE/office automation, `ALSM_EXCEL_TO_INTERNAL_TABLE`) — fragile and dialog-only. Proven libraries: **abap2xlsx** (`ZCL_EXCEL`, a clean OO class, generating/reading `.xlsx` on the server, background and dialog), **XLSX Workbench** (`ZXLWB` — a **program/transaction**, not a class, a visual SMARTFORMS-like form designer), **xtt** (Xml Template Toolkit, a template engine for Excel/Word/PDF — `ZCL_XTT_EXCEL_XLSX`/`ZCL_XTT_WORD_DOCX`/`ZCL_XTT_PDF` + `merge( )`). Choice: programmatic read/generate of `.xlsx` — abap2xlsx; a template with formulas/charts, and also Word/PDF — xtt; designing an Excel form without code — XLSX Workbench.
