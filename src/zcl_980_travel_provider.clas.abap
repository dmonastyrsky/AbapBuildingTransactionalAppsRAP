CLASS zcl_980_travel_provider DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS get_agency_by_user
      IMPORTING i_user             TYPE syuname
      RETURNING VALUE(r_agency_id) TYPE /dmo/agency_id.

    CLASS-METHODS get_next_travelid
      RETURNING VALUE(r_travel_id) TYPE /dmo/travel_id.

    " New global helper method for generating fake customers in tests
    CLASS-METHODS get_next_customer_id
      RETURNING VALUE(r_customer_id) TYPE /dmo/customer_id.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA next_travel_id TYPE /dmo/travel_id.

    " Data containers moved from local class
    CLASS-DATA customer_ids   TYPE STANDARD TABLE OF /dmo/customer_id WITH EMPTY KEY.
    CLASS-DATA customer_index TYPE i.
ENDCLASS.


CLASS zcl_980_travel_provider IMPLEMENTATION.

  METHOD get_agency_by_user.
    SELECT SINGLE agency_id FROM /dmo/agency INTO @r_agency_id.
    IF sy-subrc <> 0.
      r_agency_id = '070015'.
    ENDIF.
  ENDMETHOD.


  METHOD get_next_travelid.
    IF next_travel_id IS INITIAL.
      SELECT SINGLE FROM z980_travel FIELDS MAX( travel_id ) INTO @next_travel_id.
      IF next_travel_id IS INITIAL.
        next_travel_id = '00000000'.
      ENDIF.
    ENDIF.

    next_travel_id += 1.
    r_travel_id = |{ next_travel_id ALPHA = IN }|.
  ENDMETHOD.


  METHOD get_next_customer_id.
    " Buffer the customer IDs from the database if not loaded yet
    IF customer_ids IS INITIAL.
      SELECT FROM /dmo/customer
        FIELDS customer_id
        ORDER BY customer_id
        INTO TABLE @customer_ids.
    ENDIF.

    IF customer_ids IS INITIAL.
      r_customer_id = '000001'.
      RETURN.
    ENDIF.

    " Rotate table rows for sequential assignment
    customer_index += 1.
    IF customer_index > lines( customer_ids ).
      customer_index = 1.
    ENDIF.

    r_customer_id = customer_ids[ customer_index ].
  ENDMETHOD.

ENDCLASS.

