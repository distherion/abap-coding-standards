CLASS zcl_period DEFINITION.
  PUBLIC SECTION.
    METHODS set
      IMPORTING
        iv_begda TYPE dats
        iv_endda TYPE dats.
ENDCLASS.

METHOD copy_period.
  DATA: lv_begda TYPE string,
        lv_endda TYPE string.

  lv_begda = iv_begda_text.
  lv_endda = iv_endda_text.

  mo_period->set( iv_begda = lv_begda
                  iv_endda = lv_endda ).
ENDMETHOD.
