" Infotype 0007 write path: the Time Management Status is defaulted by the TMSTA feature.
METHOD get_zterf.
  DATA lv_werks TYPE persa.
  DATA lv_molga TYPE molga.
  DATA ls_pme01 TYPE pme01.

  SELECT SINGLE werks FROM pa0001 INTO @lv_werks
    WHERE pernr = @iv_pernr
      AND begda <= @iv_begda
      AND endda >= @iv_begda.

  SELECT SINGLE molga FROM t500p INTO @lv_molga
    WHERE persa = @lv_werks.

  ls_pme01-pernr = iv_pernr.
  ls_pme01-werks = lv_werks.
  ls_pme01-molga = lv_molga.

  CALL FUNCTION 'HR_FEATURE_BACKFIELD'
    EXPORTING
      feature       = 'TMSTA'
      struc_content = ls_pme01
    IMPORTING
      back          = rv_zterf
    EXCEPTIONS
      OTHERS        = 1.
  IF sy-subrc <> 0.
    CLEAR rv_zterf.
  ENDIF.
ENDMETHOD.
