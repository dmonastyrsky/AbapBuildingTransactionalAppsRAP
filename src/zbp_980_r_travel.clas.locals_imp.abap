CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS cancel_travel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~cancel_travel.
    METHODS set_initial_status FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~set_initial_status.

ENDCLASS.


CLASS lhc_travel IMPLEMENTATION.

  METHOD get_instance_authorizations.
    " Group incoming keys and initialize the result structure
    result = CORRESPONDING #( keys ).

    LOOP AT result ASSIGNING FIELD-SYMBOL(<result>).

      " Perform standard ABAP authority check instead of the missing helper class.
      " NOTE: Replace 'S_AGENCY' with your custom authorization object if you created one.
      AUTHORITY-CHECK OBJECT 'S_AGENCY'
        ID 'AGENCYID' FIELD <result>-agencyid
        ID 'ACTVT'    FIELD '02'. " '02' stands for 'Change/Modify'


      " If the user lacks authorization (sy-subrc is not 0), restrict access
      IF sy-subrc <> 0 AND abap_false = abap_true.
        <result>-%action-cancel_travel = if_abap_behv=>auth-unauthorized.
        <result>-%update               = if_abap_behv=>auth-unauthorized.
      ELSE.
        " If authorized, explicitly allow the operations
        <result>-%action-cancel_travel = if_abap_behv=>auth-allowed.
        <result>-%update               = if_abap_behv=>auth-allowed.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.


  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD cancel_travel.
    " Internal table to collect travel instances for bulk update
    DATA lt_travel_update TYPE TABLE FOR UPDATE z980_r_travel\\Travel.

    " 1. Read existing travel instance data using LOCAL MODE directly with input keys
    " The RAP framework automatically ensures type safety and clean formatting of keys
    READ ENTITIES OF z980_r_travel IN LOCAL MODE
      ENTITY Travel
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_travels).

    " 2. Process instances and validate current business status
    LOOP AT lt_travels ASSIGNING FIELD-SYMBOL(<travel>).

      " Check if the travel is not canceled yet ('C' stands for Cancelled)
      IF <travel>-status <> 'C'.
        " Buffer the status change for mass database modification
        APPEND VALUE #( %tky   = <travel>-%tky
                        status = 'C' ) TO lt_travel_update.
      ELSE.
        " If already canceled, block execution and register a Fiori UI failure
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.

        " Instantiate custom exception/message class with dynamic context data
        APPEND VALUE #(
          %tky = <travel>-%tky
          %msg = NEW zcm_980_travel(
                   textid       = zcm_980_travel=>already_canceled
                   severity     = if_abap_behv_message=>severity-error
                   iv_travel_id = <travel>-TravelId " Pass typed /dmo/travel_id value to replace &1
                 )
        ) TO reported-travel.
      ENDIF.

    ENDLOOP.

    " 3. Apply mass modifications to the business object outside the processing loop
    IF lt_travel_update IS NOT INITIAL.
      MODIFY ENTITIES OF z980_r_travel IN LOCAL MODE
        ENTITY Travel
          UPDATE FIELDS ( status )
          WITH lt_travel_update.
    ENDIF.
  ENDMETHOD.


  METHOD set_initial_status.
    " Read the current status of the newly created travel instances
    READ ENTITIES OF z980_r_travel IN LOCAL MODE
      ENTITY Travel
        FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_travels).

    " Internal table to store instances requiring default status update
    DATA lt_travel_update TYPE TABLE FOR UPDATE z980_r_travel\\Travel.

    LOOP AT lt_travels ASSIGNING FIELD-SYMBOL(<travel>).
      " If the status field is empty, assign the default 'O' (Open) status
      IF <travel>-Status IS INITIAL.
        APPEND VALUE #( %tky   = <travel>-%tky
                        Status = 'O' ) TO lt_travel_update.
      ENDIF.
    ENDLOOP.

    " Apply mass update to set the initial status in the database buffer
    IF lt_travel_update IS NOT INITIAL.
      MODIFY ENTITIES OF z980_r_travel IN LOCAL MODE
        ENTITY Travel
          UPDATE FIELDS ( Status ) WITH lt_travel_update.
    ENDIF.
  ENDMETHOD.


ENDCLASS.

