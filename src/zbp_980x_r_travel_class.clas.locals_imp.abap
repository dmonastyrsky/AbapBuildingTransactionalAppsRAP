CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS ZZvalidateClass FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~ZZvalidateClass.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD ZZvalidateClass.
    CONSTANTS c_area TYPE string VALUE `CLASS`.

    READ ENTITIES OF z980_r_travel IN LOCAL MODE
      ENTITY item
      FIELDS ( agencyid travelid ZZclassZIT )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).

      APPEND VALUE #( %tky = <item>-%tky
                      %state_area = c_area
                     )
          TO reported-item.

      IF <item>-ZZclassZIT IS INITIAL.

        APPEND VALUE #(  %tky = <item>-%tky )
            TO failed-item.

        APPEND VALUE #( %tky = <item>-%tky
                        %msg               = NEW zcm_980_travel(
                                               textid     = zcm_980_travel=>field_empty
                                               severity   = if_abap_behv_message=>severity-error
                                               field_name = 'Booking Class' )
                        %element-zzclasszit = if_abap_behv=>mk-on
                        %state_area = c_area
                        %path-travel = CORRESPONDING #( <item> )
                       )
            TO reported-item.
      ELSE.

        SELECT SINGLE
          FROM Z980_I_CLASS_VH
        FIELDS classid
         WHERE classid = @<item>-zzclasszit
          INTO @DATA(dummy).

        IF sy-subrc <> 0.

          APPEND VALUE #(  %tky = <item>-%tky )
              TO failed-item.

          APPEND VALUE #( %tky               = <item>-%tky
                          %msg               = NEW zcm_980_travel(
                                                 textid        = zcm_980_travel=>class_not_exist
                                                 severity      = if_abap_behv_message=>severity-error
                                                 booking_class = <item>-ZZClassZIT )
                          %element-ZZClassZIT = if_abap_behv=>mk-on
                          %state_area         = c_area
                          %path-travel       = CORRESPONDING #( <item> ) ) TO reported-item.

        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_Z980_R_TRAVEL DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_Z980_R_TRAVEL IMPLEMENTATION.

  METHOD save_modified.

*    LOOP AT update-item ASSIGNING FIELD-SYMBOL(<item>)
*    WHERE %control-ZZclassZIT = if_abap_behv=>mk-on.
*
*    UPDATE z980_tritem
*      SET zzclasszit = @<item>-ZZClassZIT
*      WHERE item_uuid  = @<item>-ItemUuid.
*
*    ENDLOOP.
*
*    LOOP AT create-item ASSIGNING <item>
*    WHERE %control-ZZclassZIT = if_abap_behv=>mk-on.
*
*    UPDATE z980_tritem
*      SET zzclasszit = @<item>-ZZclassZIT
*      WHERE item_uuid  = @<item>-ItemUuid.
*
*  ENDLOOP.


  DATA(items) = update-item.
  APPEND LINES OF create-item TO items.

  LOOP AT items ASSIGNING FIELD-SYMBOL(<item>)
    WHERE %control-ZZclassZIT = if_abap_behv=>mk-on.

    UPDATE z980_tritem
      SET zzclasszit = @<item>-ZZClassZIT
      WHERE item_uuid = @<item>-ItemUuid.

  ENDLOOP.


  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
