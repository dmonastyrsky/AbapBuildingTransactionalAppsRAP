
CLASS ZCL_980_TRAVEL_FILL_OLD DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

    CONSTANTS c_travel_table  TYPE tabname VALUE 'Z980_TRAVEL'.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_980_TRAVEL_FILL_OLD IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    TRY.
        DATA(dbtable) = NEW lcl_dbtable( c_travel_table ).

        IF dbtable->check_compatible( ) <> abap_true.

        ENDIF.

        IF dbtable->is_empty( ) <> abap_true.
          dbtable->delete_data( ).
        ENDIF.

        dbtable->generate_data( ).

      CATCH cx_abap_not_a_table.
        out->write( |{ c_travel_table } is not the name of a database table| ).
      CATCH cx_abap_not_in_package.
        out->write( |{ c_travel_table } is not a table in software component ZLOCAL| ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
