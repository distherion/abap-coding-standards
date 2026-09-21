METHOD read_first.
  DATA: lt_pernr TYPE TABLE OF pernr,
        lv_row   TYPE pernr.

  SELECT pernr FROM pa0001 INTO TABLE @lt_pernr
    WHERE begda <= @sy-datum AND endda >= @sy-datum.

  rv_first = lt_pernr[ 0 ].

  READ TABLE lt_pernr INTO lv_row INDEX 0.
  rv_second = lv_row.

  rv_count = lines( lt_pernr ).
ENDMETHOD.
