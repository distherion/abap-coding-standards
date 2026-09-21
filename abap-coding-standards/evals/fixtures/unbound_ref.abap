METHOD refresh_manager.
  DATA lo_manager TYPE REF TO zcl_employee.

  IF iv_manager_pernr IS NOT INITIAL.
    lo_manager = mo_repository->find( iv_manager_pernr ).
  ENDIF.

  lv_manager_pernr = lo_manager->get_pernr( ).
  lv_manager_name  = lo_manager->get_name( ).

  DATA(lv_text) = |{ lv_manager_pernr } { lv_manager_name }|.
  WRITE: / lv_text.
ENDMETHOD.
