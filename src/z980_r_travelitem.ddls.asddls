@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]   //equals the default and is optional
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flight Travel Item'
@AbapCatalog.extensibility: {
  extensible: true,
  allowNewDatasources: false,
  dataSources: ['_Extension'],
  elementSuffix: 'ZIT'
}
define view entity Z980_R_TRAVELITEM
  as select from z980_tritem
  association to parent Z980_R_TRAVEL as _Travel on  $projection.AgencyId = _Travel.AgencyId
                                                 and $projection.TravelId = _Travel.TravelId
  association to Z980_E_TravelItem    as _Extension   
     on $projection.ItemUuid = _Extension.ItemUuid                                               
{
  key item_uuid             as ItemUuid,
      agency_id             as AgencyId,
      travel_id             as TravelId,
      carrier_id            as CarrierId,
      connection_id         as ConnectionId,
      flight_date           as FlightDate,
      booking_id            as BookingId,
      passenger_first_name  as PassengerFirstName,
      passenger_last_name   as PassengerLastName,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,

      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      _Travel,
      _Extension
}
