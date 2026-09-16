METHOD run_employee_report.
  DATA: lv_where  TYPE string,
        lv_tcode  TYPE tcode,
        lt_pa0008 TYPE TABLE OF pa0008.

  lv_tcode = iv_tcode.
  lv_where = |pernr = '{ iv_pernr }' AND begda <= '{ sy-datum }'|.

  SELECT * FROM pa0008 WHERE (lv_where) INTO TABLE @lt_pa0008.

  CALL TRANSACTION lv_tcode WITHOUT AUTHORITY-CHECK.
ENDMETHOD.
