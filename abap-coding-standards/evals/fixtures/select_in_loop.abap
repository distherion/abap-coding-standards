METHOD get_names.
  DATA: lt_pernr  TYPE TABLE OF pernr,
        lt_result TYPE TABLE OF ty_result.

  SELECT pernr FROM pa0001 INTO TABLE @lt_pernr
    WHERE begda <= @sy-datum AND endda >= @sy-datum.

  LOOP AT lt_pernr INTO DATA(lv_pernr).
    SELECT SINGLE nachn vornm FROM pa0002 INTO @DATA(ls_name)
      WHERE pernr = @lv_pernr.
    APPEND VALUE #( pernr = lv_pernr
                    name  = |{ ls_name-nachn } { ls_name-vornm }| ) TO lt_result.
  ENDLOOP.

  WRITE: / 'done'.

  DATA(lv_dummy) = 1.
  DATA(lv_other) = 2.
ENDMETHOD.
