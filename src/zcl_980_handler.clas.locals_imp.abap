CLASS lcl_handler DEFINITION
  INHERITING FROM cl_abap_behavior_event_handler.

  PRIVATE SECTION.
    METHODS on_travel_created FOR ENTITY EVENT
      IMPORTING new_travels
        FOR Travel~TravelCreated.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_travel_created.
*    DATA log TYPE TABLE FOR CREATE z980_i_travellog.
*
*    LOOP AT new_travels ASSIGNING FIELD-SYMBOL(<travel>).
*      APPEND VALUE #( AgencyID = <travel>-agencyid
*                      TravelID = <travel>-travelid
*                      Origin   = 'Z980_R_TRAVEL (MODEVI)' )
*        TO log.
*    ENDLOOP.
*
*    MODIFY ENTITIES OF z980_i_travellog
*      ENTITY TravelLog
*        CREATE AUTO FILL CID
*        FIELDS ( AgencyID TravelID Origin )
*        WITH log.

    MODIFY ENTITIES OF z980_i_travellog
      ENTITY TravelLog
        CREATE AUTO FILL CID
        FIELDS ( AgencyID TravelID Origin )
        WITH CORRESPONDING #( new_travels ).

  ENDMETHOD.

ENDCLASS.
