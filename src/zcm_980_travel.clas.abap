CLASS zcm_980_travel DEFINITION
  PUBLIC
  INHERITING FROM cx_no_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_abap_behv_message .
    INTERFACES if_t100_message .
    INTERFACES if_t100_dyn_msg .

    " Exception text constants mapped to T100 messages
    CONSTANTS:
      BEGIN OF already_canceled,
        msgid TYPE symsgid      VALUE 'ZMS_S4D437',   " Your custom message class from SE91
        msgno TYPE symsgno      VALUE '001',          " Message number without leading spaces
        attr1 TYPE scx_attrname VALUE 'MV_TRAVEL_ID', " Points to the variable below to replace &1
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF already_canceled .

    " Context data placeholder for dynamic message text
    DATA mv_travel_id TYPE string .

    METHODS constructor
      IMPORTING
        textid       LIKE if_t100_message=>t100key          OPTIONAL
        severity     LIKE if_abap_behv_message~m_severity OPTIONAL
        iv_travel_id TYPE string                            OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcm_980_travel IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( ).

    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.

    " Assign message severity (defaults to Error)
    IF severity IS INITIAL.
      if_abap_behv_message~m_severity = if_abap_behv_message=>severity-error.
    ELSE.
      if_abap_behv_message~m_severity = severity.
    ENDIF.

    " Save dynamic context data
    me->mv_travel_id = iv_travel_id.

  ENDMETHOD.
ENDCLASS.

