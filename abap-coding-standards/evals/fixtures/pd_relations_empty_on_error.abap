METHOD ensure_assignment.
  DATA: lt_relations TYPE p1001tab,
        ls_relation  TYPE p1001.

  io_employee->get_relations(
    EXPORTING
      rsign     = 'B'
      relat     = '008'
      sclas     = 'S'
      sobid     = iv_position
    IMPORTING
      relations = lt_relations
      is_ok     = DATA(lv_ok)
      message_handler = io_message_handler ).

  IF lt_relations IS INITIAL.
    ls_relation-rsign = 'B'.
    ls_relation-relat = '008'.
    ls_relation-sclas = 'S'.
    ls_relation-sobid = iv_position.
    ls_relation-begda = iv_begda.
    ls_relation-endda = '99991231'.

    io_employee->create_relation(
      EXPORTING
        is_relation = ls_relation
      IMPORTING
        is_ok       = DATA(lv_created_ok) ).
    raise_if_not_ok( io_message_handler ).
  ENDIF.
ENDMETHOD.
