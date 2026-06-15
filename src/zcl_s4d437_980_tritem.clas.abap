CLASS zcl_s4d437_980_tritem DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        i_table_name TYPE string.

    METHODS delete_item
      IMPORTING
        i_uuid        TYPE sysuuid_x16
      RETURNING
        VALUE(r_msg) TYPE symsg.

    " Mapped parameters to your concrete structure to guarantee Unicode convertibility
    METHODS create_item
      IMPORTING
        i_item        TYPE z980_s_tritem
      RETURNING
        VALUE(r_msg) TYPE symsg.

    METHODS update_item
      IMPORTING
        i_item        TYPE z980_s_tritem
        i_itemx       TYPE z980_s_tritemx
      RETURNING
        VALUE(r_msg) TYPE symsg.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mv_table_name TYPE string.
ENDCLASS.



CLASS zcl_s4d437_980_tritem IMPLEMENTATION.

  METHOD constructor.
    mv_table_name = to_upper( i_table_name ).
  ENDMETHOD.


  METHOD delete_item.
    " Using your exact table and column for standard safe execution
    DELETE FROM z980_tritem WHERE item_uuid = @i_uuid.
    IF sy-subrc <> 0.
      " Fixed: Assigning string to a specific field component of symsg structure
      r_msg-msgty = 'E'.
      r_msg-msgid = '00'.
      r_msg-msgno = '001'.
      r_msg-msgv1 = 'ERROR_DELETE'.
    ENDIF.
  ENDMETHOD.


  METHOD create_item.
    " Create a database row buffer and map fields safely from the structure
    DATA ls_db_row TYPE z980_tritem.
    ls_db_row = CORRESPONDING #( i_item ).

    INSERT z980_tritem FROM @ls_db_row.
    IF sy-subrc <> 0.
      " Fixed: Properly filling symsg components
      r_msg-msgty = 'E'.
      r_msg-msgid = '00'.
      r_msg-msgno = '001'.
      r_msg-msgv1 = 'ERROR_CREATE'.
    ENDIF.
  ENDMETHOD.


  METHOD update_item.
    " Read current state statically using the correct key field name
    SELECT SINGLE * FROM z980_tritem
      WHERE item_uuid = @i_item-item_uuid
      INTO @DATA(ls_current_db_state).

    IF sy-subrc = 0.
      DATA(lo_struct_descr) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( i_itemx ) ).

      LOOP AT lo_struct_descr->components ASSIGNING FIELD-SYMBOL(<ls_comp>).
        DATA(lv_comp_name) = to_upper( <ls_comp>-name ).

        " Skip structural administrative markers and keys
        IF lv_comp_name = 'MANDT'     OR
           lv_comp_name = 'ITEM_UUID' OR
           lv_comp_name = 'CREATED_BY' OR
           lv_comp_name = 'CREATED_AT' OR
           lv_comp_name = 'LOCAL_LAST_CHANGED_BY' OR
           lv_comp_name = 'LOCAL_LAST_CHANGED_AT' OR
           lv_comp_name = 'LAST_CHANGED_AT'.
          CONTINUE.
        ENDIF.

        " Verify via x-structure if the field was updated by the user (flag is active)
        ASSIGN COMPONENT <ls_comp>-name OF STRUCTURE i_itemx TO FIELD-SYMBOL(<lv_flag>).
        IF <lv_flag> IS ASSIGNED AND ( <lv_flag> = '01' OR <lv_flag> = 'X' ).

          ASSIGN COMPONENT <ls_comp>-name OF STRUCTURE i_item TO FIELD-SYMBOL(<lv_new_value>).
          ASSIGN COMPONENT <ls_comp>-name OF STRUCTURE ls_current_db_state TO FIELD-SYMBOL(<lv_db_value>).

          IF <lv_new_value> IS ASSIGNED AND <lv_db_value> IS ASSIGNED.
            <lv_db_value> = <lv_new_value>.
          ENDIF.
        ENDIF.
        UNASSIGN: <lv_flag>, <lv_new_value>, <lv_db_value>.
      ENDLOOP.

      UPDATE z980_tritem FROM @ls_current_db_state.
      IF sy-subrc <> 0.
        " Fixed: Filling symsg for update error
        r_msg-msgty = 'E'.
        r_msg-msgid = '00'.
        r_msg-msgno = '001'.
        r_msg-msgv1 = 'ERROR_UPDATE'.
      ENDIF.
    ELSE.
      " Fixed: Filling symsg for not found error
      r_msg-msgty = 'E'.
      r_msg-msgid = '00'.
      r_msg-msgno = '001'.
      r_msg-msgv1 = 'NOT_FOUND'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

