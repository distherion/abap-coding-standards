METHOD collect_wage_types.
  DATA: lt_pernr TYPE TABLE OF pernr,
        lt_betrg TYPE TABLE OF ty_betrg.

  SELECT pernr FROM pa0001 INTO TABLE @lt_pernr
    WHERE begda <= @sy-datum AND endda >= @sy-datum.

  LOOP AT lt_pernr INTO DATA(lv_pernr).
    IMPORT payru_result FROM DATABASE pcl2(ur) ID lv_pernr
      IGNORING STRUCTURE BOUNDARIES.

    SELECT SINGLE lgtxt FROM t512t INTO @DATA(lv_lgtxt)
      WHERE sprsl = @sy-langu AND molga = '33' AND lgart = '1000'.

    APPEND VALUE #( pernr = lv_pernr
                    text  = lv_lgtxt ) TO lt_betrg.
  ENDLOOP.
ENDMETHOD.
