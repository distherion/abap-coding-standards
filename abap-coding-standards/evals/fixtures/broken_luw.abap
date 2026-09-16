METHOD post_payment.
  DATA: ls_reguh TYPE reguh.

  ls_reguh = VALUE #( lifnr = iv_lifnr belnr = iv_belnr ).
  INSERT reguh FROM ls_reguh.
  COMMIT WORK.

  LOOP AT it_regup INTO DATA(ls_regup).
    INSERT regup FROM ls_regup.
  ENDLOOP.
  COMMIT WORK.
ENDMETHOD.
