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
        msgid TYPE symsgid      VALUE 'ZCM_S4D437',
        msgno TYPE symsgno      VALUE '001',
        attr1 TYPE scx_attrname VALUE 'TRAVEL_ID',  " Points to travel_id attribute
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF already_canceled,

      BEGIN OF field_empty,
        msgid TYPE symsgid      VALUE 'ZCM_S4D437',
        msgno TYPE symsgno      VALUE '002',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF field_empty,

      BEGIN OF customer_not_exist,
        msgid TYPE symsgid      VALUE 'ZCM_S4D437',
        msgno TYPE symsgno      VALUE '003',
        attr1 TYPE scx_attrname VALUE 'CUSTOMER_ID', " Points to customer_id attribute
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF customer_not_exist,

      BEGIN OF begin_date_past,
        msgid TYPE symsgid      VALUE 'ZCM_S4D437',
        msgno TYPE symsgno      VALUE '004',
        attr1 TYPE scx_attrname VALUE 'BEGIN_DATE',  " Fixed: Points to begin_date attribute
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF begin_date_past,

      BEGIN OF end_date_past,
        msgid TYPE symsgid      VALUE 'ZCM_S4D437',
        msgno TYPE symsgno      VALUE '005',
        attr1 TYPE scx_attrname VALUE 'END_DATE',    " Fixed: Points to end_date attribute
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF end_date_past,

      " Fixed syntax: replaced dot with comma below to prevent compilation error
      BEGIN OF dates_wrong_sequence,
        msgid TYPE symsgid      VALUE 'ZCM_S4D437',
        msgno TYPE symsgno      VALUE '006',
        attr1 TYPE scx_attrname VALUE 'END_DATE',    " Fixed: Maps EndDate to &1
        attr2 TYPE scx_attrname VALUE 'BEGIN_DATE',  " Fixed: Maps BeginDate to &2
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF dates_wrong_sequence.

    " Clean, standard context data placeholders (Must be UPPERCASE for T100 mapping)
    DATA travel_id   TYPE /dmo/travel_id .
    DATA customer_id TYPE /dmo/customer_id .
    DATA begin_date  TYPE /dmo/begin_date .
    DATA end_date    TYPE /dmo/end_date .

    METHODS constructor
      IMPORTING
        textid      LIKE if_t100_message=>t100key          OPTIONAL
        severity    LIKE if_abap_behv_message~m_severity OPTIONAL
        travel_id   TYPE /dmo/travel_id                    OPTIONAL
        customer_id TYPE /dmo/customer_id                  OPTIONAL
        begin_date  TYPE /dmo/begin_date                   OPTIONAL
        end_date    TYPE /dmo/end_date                     OPTIONAL.

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

    IF severity IS INITIAL.
      if_abap_behv_message~m_severity = if_abap_behv_message=>severity-error.
    ELSE.
      if_abap_behv_message~m_severity = severity.
    ENDIF.

    " Save dynamic context data using clean assignment
    me->travel_id   = travel_id.
    me->customer_id = customer_id.
    me->begin_date  = begin_date.  " Saved field
    me->end_date    = end_date.    " Saved field

  ENDMETHOD.
ENDCLASS.

