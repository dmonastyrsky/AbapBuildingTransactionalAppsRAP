CLASS lsc_z980_r_travel DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.

  PRIVATE SECTION.
    METHODS
      map_message
        IMPORTING
          i_msg        TYPE symsg
        RETURNING
          VALUE(r_msg) TYPE REF TO if_abap_behv_message.

ENDCLASS.

CLASS lsc_z980_r_travel IMPLEMENTATION.

  METHOD save_modified.

    DATA(model) = NEW zcl_s4d437_980_tritem(
                       i_table_name = 'Z980_TRITEM' ).

    " Loop over deleted items
    LOOP AT delete-item ASSIGNING FIELD-SYMBOL(<item_d>).
      DATA(msg_d) = model->delete_item( i_uuid = <item_d>-itemuuid ).

      IF msg_d IS NOT INITIAL.
        APPEND VALUE #( %tky-itemuuid = <item_d>-itemuuid
                        %msg          = map_message( msg_d ) )
          TO reported-item.
      ENDIF.
    ENDLOOP.

    " Loop over created items
    LOOP AT create-item ASSIGNING FIELD-SYMBOL(<item_c>).
      DATA(msg_c) = model->create_item( i_item = CORRESPONDING z980_s_tritem( <item_c> MAPPING FROM ENTITY ) ).

      IF msg_c IS NOT INITIAL.
        APPEND VALUE #( %tky-itemuuid = <item_c>-itemuuid
                        %msg          = map_message( msg_c ) )
          TO reported-item.
      ENDIF.
    ENDLOOP.

    " Loop over updated items
    LOOP AT update-item ASSIGNING FIELD-SYMBOL(<item_u>).
      DATA(msg_u) =  model->update_item(
        i_item  = CORRESPONDING z980_s_tritem( <item_u> MAPPING FROM ENTITY )
        i_itemx = CORRESPONDING z980_s_tritemx( <item_u> MAPPING FROM ENTITY USING CONTROL )
      ).

      IF msg_u IS NOT INITIAL.
          APPEND VALUE #( %tky-itemuuid = <item_u>-itemuuid
                          %msg          = map_message( msg_u ) )
            TO reported-item.
        ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD map_message.

    DATA(severity) = SWITCH #( i_msg-msgty
      WHEN 'S' THEN if_abap_behv_message=>severity-success
      WHEN 'I' THEN if_abap_behv_message=>severity-information
      WHEN 'W' THEN if_abap_behv_message=>severity-warning
      WHEN 'E' THEN if_abap_behv_message=>severity-error
      ELSE          if_abap_behv_message=>severity-none ).

    r_msg = new_message(
        id       = i_msg-msgid
        number   = i_msg-msgno
        severity = severity
        v1       = i_msg-msgv1
        v2       = i_msg-msgv2
        v3       = i_msg-msgv3
        v4       = i_msg-msgv4 ).

  ENDMETHOD.

ENDCLASS.

CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateFlightDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~validateFlightDate.
    METHODS determineTravelDates FOR DETERMINE ON SAVE
      IMPORTING keys FOR Item~determineTravelDates.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD validateFlightDate.

    CONSTANTS c_area TYPE string VALUE `FLIGHTDATE`.

    READ ENTITIES OF z980_r_travel IN LOCAL MODE
      ENTITY Item
      FIELDS ( AgencyId TravelId FlightDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).

      APPEND VALUE #( %tky        = <item>-%tky
                      %state_area = c_area ) TO reported-item.

      IF <item>-FlightDate IS INITIAL.
        APPEND VALUE #( %tky = <item>-%tky ) TO failed-item.

        APPEND VALUE #( %tky               = <item>-%tky
                        %msg               = NEW zcm_980_travel(
                                               textid   = zcm_980_travel=>field_empty
                                               severity = if_abap_behv_message=>severity-error
                                               field_name = 'Flight Date' )
                        %element-FlightDate = if_abap_behv=>mk-on
                        %state_area         = c_area
                        %path-travel = CORRESPONDING #( <item> ) ) TO reported-item.

      ELSEIF <item>-FlightDate < cl_abap_context_info=>get_system_date( ).
        APPEND VALUE #( %tky = <item>-%tky ) TO failed-item.

        APPEND VALUE #( %tky               = <item>-%tky
                        %msg               = NEW zcm_980_travel(
                                               textid     = zcm_980_travel=>flight_date_past
                                               severity   = if_abap_behv_message=>severity-error
                                               flight_date = <item>-FlightDate )
                        %element-FlightDate = if_abap_behv=>mk-on
                        %state_area         = c_area
                        %path-travel = CORRESPONDING #( <item> ) ) TO reported-item.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD determineTravelDates.

    READ ENTITIES OF z980_r_travel IN LOCAL MODE
      ENTITY Item
      FIELDS ( AgencyId TravelId FlightDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items)
      BY \_Travel
          FIELDS ( BeginDate EndDate )
          WITH CORRESPONDING #( keys )
          RESULT DATA(travels)
          LINK DATA(link).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).

*      ASSIGN travels[ %tky = link[ source-%tky = <item>-%tky ]-target-%tky ]
*          TO FIELD-SYMBOL(<travel>).

*      READ TABLE travels ASSIGNING FIELD-SYMBOL(<travel>)
*            WITH KEY %tky = link[ source-%tky = <item>-%tky ]-target-%tky.
*

      ASSIGN travels[ KEY id %tky =
        link[ KEY id source-%tky = <item>-%tky ]-target-%tky ]
          TO FIELD-SYMBOL(<travel>).

      IF <travel>-EndDate < <item>-FlightDate.
        <travel>-EndDate = <item>-FlightDate.
      ENDIF.

      IF <item>-FlightDate > cl_abap_context_info=>get_system_date( )
        AND <item>-FlightDate  < <travel>-BeginDate.
        <travel>-BeginDate = <item>-FlightDate.
      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF Z980_R_Travel IN LOCAL MODE
      ENTITY Travel
        UPDATE
        FIELDS ( BeginDate EndDate )
        WITH CORRESPONDING #( travels ).

  ENDMETHOD.

ENDCLASS.

CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS cancel_travel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~cancel_travel.
    METHODS determineStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~determineStatus.
    METHODS validateDescription FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDescription.
    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.
    METHODS validateBeginDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateBeginDate.
    METHODS validateEndDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateEndDate.
    METHODS determineDuration FOR DETERMINE ON SAVE
      IMPORTING keys FOR Travel~determineDuration.
    METHODS validateDateSequence FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDateSequence.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Travel.

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
                   travel_id = <travel>-TravelId " Pass typed /dmo/travel_id value to replace &1
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


  METHOD determineStatus.
    " 1. Fast read of the current status from the transactional buffer
    READ ENTITIES OF z980_r_travel IN LOCAL MODE
      ENTITY Travel
        FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_travels).

    " 2. Performance Best Practice: drop instances where status is already set
    DELETE lt_travels WHERE Status IS NOT INITIAL.
    CHECK lt_travels IS NOT INITIAL.

    " 3. Prepare dedicated local table for bulk update to prevent memory overhead
    DATA lt_travel_update TYPE TABLE FOR UPDATE z980_r_travel\\Travel.

    LOOP AT lt_travels ASSIGNING FIELD-SYMBOL(<travel>).
      APPEND VALUE #( %tky   = <travel>-%tky
                      Status = 'N' ) TO lt_travel_update.
    ENDLOOP.

    " 4. Execute single bulk mass update in the database buffer
    IF lt_travel_update IS NOT INITIAL.
      MODIFY ENTITIES OF z980_r_travel IN LOCAL MODE
        ENTITY Travel
          UPDATE FIELDS ( Status ) WITH lt_travel_update
      REPORTED DATA(lt_update_reported).

      " Fast flat mapping of identical RAP structures without expensive DEEP processing
      reported-travel = CORRESPONDING #( lt_update_reported-travel ).
    ENDIF.
  ENDMETHOD.


  METHOD earlynumbering_create.
    DATA(agencyid) = zcl_980_travel_provider=>get_agency_by_user( sy-uname ).
    mapped-travel = CORRESPONDING #( entities ).

    LOOP AT mapped-travel ASSIGNING FIELD-SYMBOL(<mapping>).
      <mapping>-AgencyId = agencyid.
      <mapping>-TravelId = zcl_980_travel_provider=>get_next_travelid( ).
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDescription.
    CONSTANTS c_area TYPE string VALUE `DESC`.

    READ ENTITIES OF z980_r_travel IN LOCAL MODE
      ENTITY Travel
      FIELDS ( Description )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      " Clear previous messages for the state area to avoid duplication on UI
      APPEND VALUE #( %tky        = <travel>-%tky
                      %state_area = c_area ) TO reported-travel.

      IF <travel>-Description IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.

        APPEND VALUE #( %tky                 = <travel>-%tky
                        %msg                 = NEW zcm_980_travel(
                                                 textid   = zcm_980_travel=>field_empty
                                                 severity = if_abap_behv_message=>severity-error
                                                 field_name = 'Description' )
                        %element-Description = if_abap_behv=>mk-on
                        %state_area         = c_area ) TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateCustomer.
    CONSTANTS c_area TYPE string VALUE `CUST`.

    READ ENTITIES OF z980_r_travel IN LOCAL MODE
      ENTITY Travel
      FIELDS ( CustomerId )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    " Create a copy of the travels table to filter and use for bulk DB read
    DATA(lt_customers) = travels.
    DELETE lt_customers WHERE CustomerId IS INITIAL.
    SORT lt_customers BY CustomerId.
    DELETE ADJACENT DUPLICATES FROM lt_customers COMPARING CustomerId.

    " Single bulk DB read using the filtered table
    IF lt_customers IS NOT INITIAL.
      SELECT FROM /dmo/i_customer
        FIELDS CustomerID
        FOR ALL ENTRIES IN @lt_customers
        WHERE CustomerID = @lt_customers-CustomerId
        INTO TABLE @DATA(lt_valid_customers).
    ENDIF.

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      " Clear previous messages for the state area to avoid duplication on UI
      APPEND VALUE #( %tky        = <travel>-%tky
                      %state_area = c_area ) TO reported-travel.

      IF <travel>-CustomerId IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.

        APPEND VALUE #( %tky                = <travel>-%tky
                        %msg                = NEW zcm_980_travel(
                                                textid   = zcm_980_travel=>field_empty
                                                severity = if_abap_behv_message=>severity-error
                                                field_name = 'Customer ID' )
                        %element-CustomerId = if_abap_behv=>mk-on
                        %state_area         = c_area ) TO reported-travel.
      ELSE.
        " Binary search on the pre-fetched internal table buffer
        READ TABLE lt_valid_customers TRANSPORTING NO FIELDS
          WITH KEY CustomerID = <travel>-CustomerId BINARY SEARCH.

        IF sy-subrc <> 0.
          APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.

          APPEND VALUE #( %tky                = <travel>-%tky
                          %msg                = NEW zcm_980_travel(
                                                  textid      = zcm_980_travel=>customer_not_exist
                                                  severity    = if_abap_behv_message=>severity-error
                                                  customer_id = <travel>-CustomerId )
                          %element-CustomerId = if_abap_behv=>mk-on
                          %state_area         = c_area ) TO reported-travel.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateBeginDate.
    CONSTANTS c_area TYPE string VALUE `BEGINDATE`.

    READ ENTITIES OF z980_r_travel IN LOCAL MODE
      ENTITY Travel
      FIELDS ( BeginDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      " Clear previous messages for the state area to avoid duplication on UI
      APPEND VALUE #( %tky        = <travel>-%tky
                      %state_area = c_area ) TO reported-travel.

      IF <travel>-BeginDate IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.

        APPEND VALUE #( %tky               = <travel>-%tky
                        %msg               = NEW zcm_980_travel(
                                               textid   = zcm_980_travel=>field_empty
                                               severity = if_abap_behv_message=>severity-error
                                               field_name = 'BStarting Date' )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %state_area         = c_area ) TO reported-travel.

      ELSEIF <travel>-BeginDate < cl_abap_context_info=>get_system_date( ).
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.

        APPEND VALUE #( %tky               = <travel>-%tky
                        %msg               = NEW zcm_980_travel(
                                               textid     = zcm_980_travel=>begin_date_past
                                               severity   = if_abap_behv_message=>severity-error
                                               begin_date = <travel>-BeginDate ) " Passed to the new clean date field
                        %element-BeginDate = if_abap_behv=>mk-on
                        %state_area         = c_area ) TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateEndDate.
    CONSTANTS c_area TYPE string VALUE `ENDDATE`.

    READ ENTITIES OF z980_r_travel IN LOCAL MODE
      ENTITY Travel
      FIELDS ( EndDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      " Clear previous messages for the state area to avoid duplication on UI
      APPEND VALUE #( %tky        = <travel>-%tky
                      %state_area = c_area ) TO reported-travel.

      IF <travel>-EndDate IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.

        APPEND VALUE #( %tky             = <travel>-%tky
                        %msg             = NEW zcm_980_travel(
                                               textid   = zcm_980_travel=>field_empty
                                               severity = if_abap_behv_message=>severity-error
                                               field_name = 'End Date' )
                        %element-EndDate = if_abap_behv=>mk-on
                        %state_area      = c_area ) TO reported-travel.

      ELSEIF <travel>-EndDate < cl_abap_context_info=>get_system_date( ).
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.

        APPEND VALUE #( %tky             = <travel>-%tky
                        %msg             = NEW zcm_980_travel(
                                               textid   = zcm_980_travel=>end_date_past
                                               severity = if_abap_behv_message=>severity-error
                                               end_date = <travel>-EndDate )
                        %element-EndDate = if_abap_behv=>mk-on
                        %state_area      = c_area ) TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateDateSequence.
    CONSTANTS c_area TYPE string VALUE `SEQUENCE`.

    READ ENTITIES OF z980_r_travel IN LOCAL MODE
      ENTITY Travel
      FIELDS ( BeginDate EndDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      " Clear previous messages for the state area to avoid duplication on UI
      APPEND VALUE #( %tky        = <travel>-%tky
                      %state_area = c_area ) TO reported-travel.

      " Only validate sequence if both dates have been entered by user
      IF <travel>-BeginDate IS NOT INITIAL AND <travel>-EndDate IS NOT INITIAL.
        IF <travel>-EndDate < <travel>-BeginDate.
          APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.

          APPEND VALUE #( %tky               = <travel>-%tky
                          %msg               = NEW zcm_980_travel(
                                                 textid     = zcm_980_travel=>dates_wrong_sequence
                                                 severity   = if_abap_behv_message=>severity-error
                                                 begin_date = <travel>-BeginDate
                                                 end_date   = <travel>-EndDate )
                          %element           = VALUE #( BeginDate = if_abap_behv=>mk-on
                                                        EndDate   = if_abap_behv=>mk-on )
                          %state_area        = c_area ) TO reported-travel.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD determineDuration.

    READ ENTITIES OF Z980_R_Travel IN LOCAL MODE
      ENTITY Travel
        FIELDS (  BeginDate EndDate )
        WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      <travel>-Duration = <travel>-EndDate - <travel>-BeginDate.
    ENDLOOP.

    MODIFY ENTITIES OF Z980_R_Travel IN LOCAL MODE
      ENTITY Travel
        UPDATE
        FIELDS ( Duration )
        WITH CORRESPONDING #( travels ).

  ENDMETHOD.

ENDCLASS.

