CLASS zcl_980_eml DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    CONSTANTS c_agency_id TYPE /dmo/agency_id VALUE '070003'.
    CONSTANTS c_travel_id TYPE /dmo/travel_id VALUE '00000001'.
ENDCLASS.


CLASS zcl_980_eml IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    READ ENTITIES OF Z980_R_Travel
         ENTITY Travel
         ALL FIELDS WITH
         VALUE #( ( AgencyId = c_agency_id
                    TravelId = c_travel_id ) )
                    " TODO: variable is assigned but never used (ABAP cleaner)
         RESULT DATA(travels)
         FAILED DATA(failed).

    IF failed IS NOT INITIAL.
      out->write( `Error retrieving the travel` ).
    ELSE.
      MODIFY ENTITIES OF Z980_R_Travel
             ENTITY Travel
             UPDATE FIELDS ( Description )
             WITH VALUE #( ( AgencyId    = c_agency_id
                             TravelId    = c_travel_id
                             Description = `Travel in the past` ) )
             FAILED failed.
      IF failed IS INITIAL.
        COMMIT ENTITIES.
        out->write( `Description successfully updated` ).
      ELSE.
        ROLLBACK ENTITIES.
        out->write( `Error updating the description` ).
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
