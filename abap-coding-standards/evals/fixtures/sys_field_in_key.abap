METHOD build_journal_key.
  rv_key = |{ iv_pernr }{ sy-datum }{ sy-sysid }|.
ENDMETHOD.

METHOD write_journal.
  DATA ls_entry TYPE zhr_journal.

  ls_entry-key   = build_journal_key( iv_pernr = iv_pernr ).
  ls_entry-pernr = iv_pernr.
  ls_entry-datum = sy-datum.
  ls_entry-uname = sy-uname.

  INSERT zhr_journal FROM @ls_entry.
ENDMETHOD.
