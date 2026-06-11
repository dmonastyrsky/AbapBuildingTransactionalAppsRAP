@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #MANDATORY

@EndUserText.label: 'Flight Travel (Data Model)'

define root view entity Z980_R_TRAVEL
  as select from z980_travel
  association [1..1] to /DMO/I_Customer as _Customer on $projection.CustomerId = _Customer.CustomerID
  composition [0..*] of Z980_R_TRAVELITEM as _TravelItem   

{
  key agency_id                               as AgencyId,
  key travel_id                               as TravelId,

      description                             as Description,
      customer_id                             as CustomerId,
      concat_with_space(_Customer.FirstName, _Customer.LastName, 1) as CustomerFullName,
      begin_date                              as BeginDate,
      end_date                                as EndDate,
      @EndUserText.label: 'Duration (days)'
      dats_days_between(begin_date, end_date) as Duration,
      status                                  as Status,

      @Semantics.user.createdBy: true
      created_by                              as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at                              as CreatedAt,

      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by                   as LocalLastChangedBy,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at                   as LocalLastChangedAt,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at                         as LastChangedAt,
      _Customer,
      _TravelItem
}
