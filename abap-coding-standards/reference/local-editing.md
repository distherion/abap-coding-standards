# Local editing of .abap files

- **[info]** abapGit — the standard open-source Git client for ABAP (`ZABAPGIT`): serializes objects (classes, programs, FM, DDIC) into human-readable files `.clas.abap`/`.clas.xml`/`.prog.abap`/`.fugr.*`/`.tabl.xml`/`.msag.xml`; versions and history are tracked by Git, not manual markup (see `style.md`). The files below are an abapGit export.
- **[behavior]** Encoding UTF-8 + LF. Legacy cp1251+CRLF files — rewrite entirely via Write into UTF-8.
- **[behavior]** **Shell/scripting utilities are forbidden** for converting or editing `.abap` (`iconv`/`sed`/`awk` on unix, PowerShell/cmd on Windows). Edit directly with Read/Edit/Write tools.
- **[P3]** Write Cyrillic directly in UTF-8 — without `\u04XX`-escapes.
- **[P3]** SE24 may add a `* <SIGNATURE>` method header; it is absent in an abapGit export — do not expect or remove it.
- **[behavior]** Syntax is unavailable locally — only activation in SAP. Note this in the output.
- **[behavior]** After edits, count the balance: `METHOD/ENDMETHOD`, `TRY/ENDTRY`, `IF/ENDIF`, `LOOP/ENDLOOP`, `CASE/ENDCASE`, `DO/ENDDO`.
