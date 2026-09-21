METHOD change_object.
  CALL FUNCTION 'ENQUEUE_E_TABLE'
    EXPORTING
      tabname        = 'HRP1000'
      varkey         = iv_objid
    EXCEPTIONS
      foreign_lock   = 1
      OTHERS         = 2.
  IF sy-subrc = 1.
    raise_busy( iv_objid = iv_objid ).
  ENDIF.

  UPDATE hrp1000 SET stext = @iv_stext
    WHERE objid = @iv_objid.

  IF iv_check_failed = abap_true.
    RETURN.
  ENDIF.

  CALL FUNCTION 'DEQUEUE_E_TABLE'
    EXPORTING
      tabname = 'HRP1000'
      varkey  = iv_objid.
ENDMETHOD.
