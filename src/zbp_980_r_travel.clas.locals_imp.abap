CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS cancel_travel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~cancel_travel.

ENDCLASS.


CLASS lhc_travel IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD cancel_travel.

    " Internal table to collect travel instances for bulk update
    DATA lt_travel_update TYPE TABLE FOR UPDATE Z980_R_Travel\\Travel.

    " 1. Read existing travel instance data using LOCAL MODE
    READ ENTITIES OF Z980_R_Travel IN LOCAL MODE
      ENTITY Travel
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

    " 2. Process instances and validate current status
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      IF <travel>-status <> 'C'.
        " If not canceled yet, buffer for mass update
        APPEND VALUE #( %tky   = <travel>-%tky
                        status = 'C' ) TO lt_travel_update.
      ELSE.
        " If already canceled, block processing and raise a Fiori UI error
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.

        " Instantiate your new custom message class ZCM_980_TRAVEL
        APPEND VALUE #(
          %tky = <travel>-%tky
          %msg = NEW zcm_980_travel(
                   textid       = zcm_980_travel=>already_canceled
                   severity     = if_abap_behv_message=>severity-error
                   iv_travel_id = CONV #( <travel>-TravelID ) )
        ) TO reported-travel.
      ENDIF.

    ENDLOOP.

    " 3. Apply mass modifications to the business object outside the loop
    IF lt_travel_update IS NOT INITIAL.
      MODIFY ENTITIES OF Z980_R_Travel IN LOCAL MODE
        ENTITY Travel
          UPDATE FIELDS ( status )
          WITH lt_travel_update.
    ENDIF.

  ENDMETHOD.

ENDCLASS.

