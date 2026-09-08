# ABAP Dictionary (DDIC) objects

## Database tables and keys

- **[P2]** The primary key is defined at table creation: key fields must be together at the **start** of the table and locked in during activation — later you can only add non-key fields at the end, a new key field cannot be added afterwards. Plan the key (and the client field, for client-dependent tables) before the table goes productive.
- **[info]** Key field constraints (ABAPDocu "Key Fields of Database Tables"): max 16 key fields, max 900 bytes; the types `FLTP`, `STRING`, `RAWSTRING`, `LCHAR`, `LRAW` (and the obsolete `DF16_SCL`/`DF34_SCL`) are **not allowed** as key fields. A key longer than 120 bytes blocks the table as a base for a lock object and content transport by full key.
- **[P2]** Access must match the key: a table is read/searched by its key or an index, not by random full scans (see `open-sql.md`); make sure the `WHERE` of the typical read is covered by the key or a secondary index (SE11 keys/indexes, ST05).

## Buffering

- **[P2]** Buffering permission (not allowed / allowed-but-off / on) and type (single / generic / full) are set in the DDIC. Turning buffering on obliges the read code to access by the buffer's rules — the list of statements that bypass the buffer (JOIN, DISTINCT, aggregates, ORDER BY not by key, `FOR UPDATE`, ...) is in `open-sql.md`; with a mismatch the buffer is silently useless (each read goes to the DB).
- **[info]** After a write to a buffered table, the next reads bypass the buffer until it is reloaded (the number of bypassing reads is set via profile parameter `zcsa/sync_reload_c`) — do not rely on the buffer for immediately repeated reads right after a write.

## Enhancing SAP objects — append structures

- **[P1]** Do not modify the core structure or root include of an SAP table/structure. Enhance SAP objects only via **append structures** in the customer namespace: not a modification, upgrade-safe, the components are appended back after an upgrade.
- **[info]** Append structures can only be appended to **transparent** tables; not to tables with `LCHR`/`LRAW` (they must stay the last fields). Appended fields can be added to secondary indexes; key fields cannot be appended (must be at the start). A binding of a check table / search help that already exists for a field cannot be changed via the append structure.
- **[info]** A structure's *enhancement category* determines what can be appended (from "cannot be enhanced" to "any type"). Code that uses offset/length on a flat structure gets a check warning, because a later enhancement can change the offsets (ABAPDocu "Enhancement Category of Structures").

## Domains and data elements

- **[P2]** One semantic per domain/data element — do not reuse one domain/data element for different meanings just because the technical type matches; a dedicated data element carries its own labels and dokumentation (UI semantics).
- **[info]** Domain semantic attributes (ABAPDocu "Semantic Attributes of Domains"): conversion routine — `..._INPUT`/`..._OUTPUT` FMs invoked for dynpro fields and `WRITE` output — verify both directions of the routine; fixed values/intervals define the value range for input help (CHAR fixed value max 10 chars; NUMC/INT/DEC — positive integers); "sign" and "lowercase" are set on the domain.
- **[info]** A **value table** in the domain is only a *default* for the check table: *"just specifying a value table does not trigger a check"* — data integrity requires a real foreign key / check table in the table definition. If you rely on a check, define it as a check table (field), not only as a domain value table.
- **[info]** Data element semantic attributes are effective only for dynpro/Web Dynpro rendering (field labels, headers, documentation); ABAP program fields ignore them. `SYST_*` data elements describe system fields and **must not appear in the UI** — for UI use dedicated data elements with their own texts (see `data.md`, "Texts and translation").