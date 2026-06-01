@AccessControl.authorizationCheck: #MANDATORY
@EndUserText.label: 'Flight Travel (Projection)'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
@Metadata.allowExtensions: true
define root view entity Z980_C_TRAVEL
  provider contract transactional_query
  as projection on Z980_R_TRAVEL
  association [1..1] to Z980_R_TRAVEL as _BaseEntity
    on  $projection.AgencyId = _BaseEntity.AgencyId
    and $projection.TravelId = _BaseEntity.TravelId
{
    key AgencyId,
    key TravelId,
    @Search.defaultSearchElement: true
    Description,
    @Search.defaultSearchElement: true
    CustomerId,
    BeginDate,
    EndDate,
    Duration,
    Status,
    CreatedBy,
    CreatedAt,
    LocalLastChangedBy,
    LocalLastChangedAt,
    LastChangedAt,
    _BaseEntity
}
