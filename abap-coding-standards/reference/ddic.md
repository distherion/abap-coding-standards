# ABAP Dictionary (DDIC) objects

> Dictionary objects and their maintenance: table keys, buffering, append structures (enhancing SAP objects), domains and data elements.
> Related: `data.md` (the language-level types these map onto), `open-sql.md` (reading with buffering in effect), `cds-amdp.md` (DDIC-based views), `security.md` (writes to standard tables).

## Database tables and keys

- **[P2]** The primary key is defined at table creation: key fields must be together at the **start** of the table and locked in during activation — a key field added later is not possible without recreating/migrating the table (the simplification "can never add a key field" is exact for a productive table). Plan the key (and the client field, for client-dependent tables) before the table goes productive.
- **[P2]** Key field constraints (ABAPDocu "Key Fields of Database Tables"): max 16 key fields, max 900 bytes; the types `FLTP`, `STRING`, `RAWSTRING`, `LCHR`, `LRAW`, `GEOM_EWKB` (and the obsolete `DF16_SCL`/`DF34_SCL`) are **not allowed** as key fields; `RAW` as a key field is limited (≤ 69 bytes for a single field). A key longer than 120 bytes blocks the table as a base for a lock object and content transport by full key.
- **[P2]** Access must match the key: a table is read/searched by its key or an index, not by random full scans (see `open-sql.md`); make sure the `WHERE` of the typical read is covered by the key or a secondary index (SE11 keys/indexes, ST05).

## Buffering

- **[P2]** Buffering permission (not allowed / allowed-but-off / on) and type (single / generic / full) are set in the DDIC. Turning buffering on obliges the read code to access by the buffer's rules — the list of statements that bypass the buffer (JOIN, DISTINCT, aggregates, ORDER BY not by key, `FOR UPDATE`, ...) is in `open-sql.md`; with a mismatch the buffer is silently useless (each read goes to the DB).
- **[P2]** After a write to a buffered table, the next reads bypass the buffer until it is reloaded (the number of bypassing reads is set via profile parameter `zcsa/sync_reload_c`) — do not rely on the buffer for immediately repeated reads right after a write.

## Enhancing SAP objects — append structures

- **[P1]** Do not modify the core structure or root include of an SAP table/structure. Enhance SAP objects only via **append structures** in the customer namespace: not a modification, upgrade-safe, the components are appended back after an upgrade. <!-- rule: append-structure-not-modify -->
- **[P3]** Append structures are a tool for enhancing **SAP** objects, not your own `Z`-tables/structures — do not extend own tables this way (your own fields there — `ZZ`/`YY`; for an SAP object look first for the Customizing Include `CI_*`); respect the enhancement category.
- **[P2]** Append structures can only be appended to **transparent** tables; not to tables with `LCHR`/`LRAW` (they must stay the last fields). Appended fields can be added to secondary indexes; key fields cannot be appended (must be at the start). A binding of a check table / search help that already exists for a field cannot be changed via the append structure.
- **[P3]** A structure's *enhancement category* determines what can be appended (from "cannot be enhanced" to "any type"). Code that uses offset/length on a flat structure gets a check warning, because a later enhancement can change the offsets (ABAPDocu "Enhancement Category of Structures").

## Domains and data elements

- **[P2]** One semantic per domain/data element — do not proliferate domains and do not reuse one domain/data element for different meanings just because the technical type matches; a dedicated data element carries its own labels and documentation (UI semantics). Reuse standard data elements (`BUKRS`, `WAERS`, `PERNR`…) — they bring a value table, search help, and translations; a custom data element only for genuinely new semantics. Flags/statuses — a domain with fixed values.
- **[P2]** Domain semantic attributes (ABAPDocu "Semantic Attributes of Domains"): conversion routine — `..._INPUT`/`..._OUTPUT` FMs invoked for dynpro fields and `WRITE` output — verify both directions of the routine; fixed values/intervals define the value range for input help (CHAR fixed value max 10 chars; NUMC/INT/DEC — positive integers); "sign" and "lowercase" are set on the domain.
- **[P2]** A **value table** in the domain is only a *default* for the check table: *"just specifying a value table does not trigger a check"* — data integrity requires a real foreign key / check table in the table definition. If you rely on a check, define it as a check table (field), not only as a domain value table.
- **[P2]** Data element semantic attributes are effective mainly for dynpro/Web Dynpro rendering (field labels, headers, documentation); ABAP program fields ignore them. `SYST_*` data elements describe system fields and **must not appear in the UI** — for UI use dedicated data elements with their own texts (see `strings.md`, "Texts and translation").


## Domains, data elements and GUID

- **[P3]** Text/value of a fixed-value domain — `cl_reca_ddic_doma` (RE-FX): `get_text_by_value( EXPORTING id_name = <domain> id_value = <value> IMPORTING ed_text = <text> )`; reverse `get_value_by_text( EXPORTING id_name id_text if_ignore_case = abap_true IMPORTING ed_value EXCEPTIONS not_found = 1 )`; full list — `get_values( EXPORTING id_name IMPORTING et_values )` (rows with `ddtext`). Do not map value↔text by hand. Without RE-FX — FM `DD_DOMVALUES_GET`/`DDIF_DOMA_GET`.

- **[P3]** Data-element label/text (short/medium/long) — `CL_RECA_DDIC_DTEL` (RE-FX), all with `id_langu = sy-langu` default and `EXCEPTIONS not_found = 1`: by data element `get_text( id_name = ... IMPORTING ed_fieldtext = ... ed_reptext = ... ed_scrtext_s/m/l = ... )`; by table field `get_text_by_fieldname( id_tabname = ... id_fieldname = ... IMPORTING ... )`; by ABAP data object `get_text_by_field( id_field = ... IMPORTING ... )` (resolves the DTEL name from the field). Existence — `exists( id_name = ... ) → rf_exists`; full definition (header `DD04V` + `TPARA` texts) — `get_complete( id_name = ... IMPORTING es_header = ... es_tpara = ... )`. Standard fallback — FM `DDIF_DTEL_GET`/`DDIF_FIELDINFO_GET`.

- **[P3]** GUID — `cl_reca_guid=>guid_create( IMPORTING ed_guid_22 = DATA(lv_guid) )` (22 chars, C22); do not assemble by hand from `sy-uzeit`/random. Without RE-FX — `cl_system_uuid=>create_uuid_c22_static( )` (available since NW 7.0; the `*_static` methods declare no `RAISING`, but SAP's own code still wraps them in `TRY ... CATCH cx_uuid_error` — keep the catch defensively).
