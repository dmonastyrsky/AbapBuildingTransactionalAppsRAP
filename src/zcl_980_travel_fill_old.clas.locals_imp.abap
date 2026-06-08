*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS lcl_travel_provider DEFINITION.

  PUBLIC SECTION.
    CLASS-METHODS get_agency_by_user
      IMPORTING i_user             TYPE syuname
      RETURNING VALUE(r_agency_id) TYPE /dmo/agency_id.

    CLASS-METHODS init_next_travelid
      IMPORTING i_tabname TYPE tabname.

    CLASS-METHODS get_next_travelid
      RETURNING VALUE(r_travel_id) TYPE /dmo/travel_id.
    CLASS-METHODS get_next_customer_id
      RETURNING VALUE(r_customer_id) TYPE /dmo/customer_id.

    CLASS-METHODS init_reference_data.

  PRIVATE SECTION.
    CLASS-DATA next_travel_id TYPE /dmo/travel_id.
    CLASS-DATA customer_ids TYPE STANDARD TABLE OF /dmo/customer_id WITH EMPTY KEY.
    CLASS-DATA customer_index TYPE i.

ENDCLASS.


CLASS lcl_travel_provider IMPLEMENTATION.
  METHOD get_agency_by_user.
    " TODO: parameter I_USER is never used (ABAP cleaner)

    " Free trial replacement for /lrn/cl_s4d437_model=>get_agency_by_user
    " ALTERNATIVE: Fetch an existing agency ID from the standard SAP demo table, or fallback to default
    SELECT SINGLE agency_id FROM /dmo/agency INTO @r_agency_id.
    IF sy-subrc <> 0.
      r_agency_id = '070015'.
    ENDIF.
  ENDMETHOD.

  METHOD init_next_travelid.
    SELECT SINGLE
      FROM (i_tabname)
      FIELDS MAX( travel_id )
      INTO @next_travel_id.

    IF next_travel_id IS INITIAL OR next_travel_id < '90000000'.
      next_travel_id = '90000000'.
    ENDIF.
  ENDMETHOD.

  METHOD get_next_travelid.
    next_travel_id += 1.
    r_travel_id = next_travel_id.
  ENDMETHOD.

  METHOD init_reference_data.

    IF customer_ids IS INITIAL.
      SELECT FROM /dmo/customer
        FIELDS customer_id
        ORDER BY customer_id
        INTO TABLE @customer_ids.
    ENDIF.

  ENDMETHOD.

  METHOD get_next_customer_id.

    IF customer_ids IS INITIAL.
      init_reference_data( ).
    ENDIF.

    IF customer_ids IS INITIAL.
      r_customer_id = '000001'.
      RETURN.
    ENDIF.

    customer_index += 1.

    IF customer_index > lines( customer_ids ).
      customer_index = 1.
    ENDIF.

    r_customer_id = customer_ids[ customer_index ].

  ENDMETHOD.

ENDCLASS.


CLASS lcl_dbtable DEFINITION.

  PUBLIC SECTION.
    DATA tabname TYPE tabname READ-ONLY.

    METHODS
      constructor
        IMPORTING i_tabname TYPE tabname
        RAISING   cx_abap_not_a_table
                  cx_abap_not_in_package.

    METHODS
      is_empty
        RETURNING VALUE(r_result) TYPE abap_bool.

    METHODS
      check_compatible
        RETURNING VALUE(r_consistent) TYPE abap_bool.

    METHODS
      has_totetag_field
        RETURNING VALUE(r_result) TYPE abap_bool.

    METHODS
      generate_data.

    METHODS
      delete_data.

  PRIVATE SECTION.
    CONSTANTS c_template TYPE tabname             VALUE 'Z980_TRAVEL'.
    CONSTANTS c_user     TYPE abp_lastchange_user VALUE 'GENERATOR'.

    TYPES tt_data TYPE STANDARD TABLE OF Z980_TRAVEL WITH NON-UNIQUE DEFAULT KEY.

    DATA today         TYPE cl_abap_context_info=>ty_system_date.

    DATA data_ref      TYPE REF TO data.

    DATA components    TYPE abap_compdescr_tab.

    DATA guid_field    TYPE abap_compname.
    DATA totetag_field TYPE abap_compname.

    METHODS add_totetag_field.

    METHODS dbselect.

    METHODS dbsync.

ENDCLASS.


CLASS lcl_dbtable IMPLEMENTATION.
  METHOD constructor.
    TRY.
        cl_abap_dyn_prg=>check_table_name_tab( val               = i_tabname
                                               packages          = VALUE #( ( `ZLOCAL` ) ( `Z98` ) ( `$TMP` ) )
                                               incl_sub_packages = abap_true ).

      CATCH cx_abap_not_in_package.
        RAISE EXCEPTION NEW cx_abap_not_a_table( ).
    ENDTRY.
    tabname = i_tabname.

    components = CAST cl_abap_structdescr(
                         cl_abap_typedescr=>describe_by_name( i_tabname )
                                           )->components.

    IF components[ lines( components ) ]-type_kind <> cl_abap_typedescr=>typekind_char.
      totetag_field = components[ lines( components ) ]-name.
    ENDIF.

    CREATE DATA data_ref TYPE TABLE OF (tabname).

    dbselect( ).

    today = cl_abap_context_info=>get_system_date( ).
  ENDMETHOD.

  METHOD check_compatible.
    " Get list of components for template
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA(lo_template) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( c_template ) ).

    DATA(t_components) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( c_template ) )->components.

    " remove loc_last changed_at from template if missing in table

    IF lines( t_components ) = lines( components ) + 1.
      DELETE t_components INDEX lines( t_components ).
    ENDIF.

    " check for compatibility of type

    r_consistent = abap_true.

    IF components <> t_components.
      r_consistent = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD is_empty.
    r_result = abap_true.
    SELECT SINGLE
      FROM (tabname)
      FIELDS @abap_false
      INTO @r_result.
  ENDMETHOD.

  METHOD has_totetag_field.
    IF totetag_field IS NOT INITIAL.
      r_result = abap_true.
    ELSE.
      r_result = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD generate_data.
    FIELD-SYMBOLS <lt_data> TYPE ANY TABLE.

    " DATA(lv_agency)   =  CAST /lrn/cl_s4d437_model=>get_agency_by_user( sy-uname ).

    DATA(lv_agency) = lcl_travel_provider=>get_agency_by_user( sy-uname ).
    lcl_travel_provider=>init_reference_data( ).

    GET TIME STAMP FIELD DATA(lv_changed_at).

    DATA(lt_data) = VALUE tt_data(

* Travel in the past
                                   status                = 'O'
                                   created_by            = c_user
                                   created_at            = lv_changed_at
                                   local_last_changed_by = c_user
                                   local_last_changed_at = lv_changed_at
                                   last_changed_at       = lv_changed_at
                                   ( agency_id   = lv_agency
                                     travel_id   = lcl_travel_provider=>get_next_travelid( ) "/lrn/cl_s4d437_model=>get_next_travelid( )
                                     description = 'Travel in the past'
                                     customer_id = lcl_travel_provider=>get_next_customer_id( )
                                     begin_date  = today - 28
                                     end_date    = today - 14 )

* ongoing travel
                                   ( agency_id   = lv_agency
                                     travel_id   = lcl_travel_provider=>get_next_travelid( ) "/lrn/cl_s4d437_model=>get_next_travelid( )
                                     description = 'Travel ongoing'
                                     customer_id = lcl_travel_provider=>get_next_customer_id( )
                                     begin_date  = today - 7
                                     end_date    = today + 14 )

* travel in the future

                                   ( agency_id   = lv_agency
                                     travel_id   = lcl_travel_provider=>get_next_travelid( ) "/lrn/cl_s4d437_model=>get_next_travelid( )
                                     description = 'Travel in the future'
                                     customer_id = lcl_travel_provider=>get_next_customer_id( )
                                     begin_date  = today + 14
                                     end_date    = today + 28 )

* travel for travel agency 070041
                                   ( agency_id   = '070041'
                                     travel_id   = lcl_travel_provider=>get_next_travelid( ) "/lrn/cl_s4d437_model=>get_next_travelid( )
                                     description = 'Travel of travel agency 70041'
                                     customer_id = 4
                                     begin_date  = today + 18
                                     end_date    = today + 26 )

* travel for travel agency 70050
                                   ( agency_id   = '070050'
                                     travel_id   = lcl_travel_provider=>get_next_travelid( ) "/lrn/cl_s4d437_model=>get_next_travelid( )
                                     description = 'Travel of agency 70050'
                                     customer_id = lcl_travel_provider=>get_next_customer_id( )
                                     begin_date  = today + 14
                                     end_date    = today + 21 ) ).

    ASSIGN data_ref->* TO <lt_data>.

    MOVE-CORRESPONDING lt_data TO <lt_data>.

*    IF guid_field IS NOT INITIAL.
*      add_guid_field( ).
*    ENDIF.

    IF totetag_field IS NOT INITIAL.
      add_totetag_field( ).
    ENDIF.

    dbsync( ).
  ENDMETHOD.

*  METHOD update_with_guid.
*
*    IF guid_field IS NOT INITIAL.
*      add_guid_field( ).
*      dbsync( ).
*
*    ENDIF.
*  ENDMETHOD.

  METHOD delete_data.
    FIELD-SYMBOLS <lt_data> TYPE ANY TABLE.

    ASSIGN data_ref->* TO <lt_data>.

    CLEAR <lt_data>.

    dbsync( ).
  ENDMETHOD.

  METHOD add_totetag_field.
    FIELD-SYMBOLS <lt_data> TYPE ANY TABLE.

    ASSIGN data_ref->* TO <lt_data>.

    LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_data>).

      ASSIGN COMPONENT totetag_field OF STRUCTURE <ls_data> TO FIELD-SYMBOL(<lv_etag>).

      IF <lv_etag> IS INITIAL.
        GET TIME STAMP FIELD <lv_etag>.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD dbselect.
    FIELD-SYMBOLS <lt_data> TYPE ANY TABLE.

    ASSIGN data_ref->* TO <lt_data>.

    SELECT
      FROM (tabname)
      FIELDS *
      INTO TABLE @<lt_data>.
  ENDMETHOD.

  METHOD dbsync.
    FIELD-SYMBOLS <lt_data> TYPE ANY TABLE.

    ASSIGN data_ref->* TO <lt_data>.

    IF <lt_data> IS INITIAL.
      DELETE FROM (tabname).
    ELSEIF is_empty( ) = abap_true.

      INSERT (tabname) FROM TABLE @<lt_data>.

    ELSE.

      MODIFY (tabname) FROM TABLE @<lt_data>.

    ENDIF.
  ENDMETHOD.
ENDCLASS.
