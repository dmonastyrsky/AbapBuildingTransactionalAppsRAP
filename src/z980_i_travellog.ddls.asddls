@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View for Travel Log'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z980_I_TRAVELLOG 
  as select from z980_travellog
{
  key log_uuid  as LogUuid,
  agency_id     as AgencyID,
  travel_id     as TravelID,
  origin        as Origin,
  @Semantics.systemDateTime.createdAt: true
  created_at    as CreatedAt
}
