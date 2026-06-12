@AccessControl.authorizationCheck: #MANDATORY
@EndUserText.label: 'Flight Travel (Projection)'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
@Metadata.allowExtensions: true
define root view entity Z980_C_TRAVEL
  provider contract transactional_query
  as projection on Z980_R_TRAVEL
  association [1..1] to Z980_R_TRAVEL as _BaseEntity on  $projection.AgencyId = _BaseEntity.AgencyId
                                                     and $projection.TravelId = _BaseEntity.TravelId
{
  @Consumption.valueHelpDefinition: [ 
        { entity: { name:    '/DMO/I_Agency_StdVH', 
                    element: 'AgencyID' } } 
      ]
  key AgencyId,
  @Consumption.valueHelpDefinition: [ 
        { entity: { name:    '/DMO/I_Travel_U', 
                    element: 'TravelID' },
          additionalBinding: [
            { localElement: 'AgencyId',    element: 'AgencyID' },   
            { localElement: 'Description', element: 'Memo' }  
          ]
        } 
      ] 
  key TravelId,
      @Search.defaultSearchElement: true
      Description,
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['CustomerFullName']
      @Consumption.valueHelpDefinition: [
        { entity: { name:    '/DMO/I_Customer_StdVH',
                    element: 'CustomerID' } } ]
      CustomerId,
      CustomerFullName as CustomerFullName,
      BeginDate,
      EndDate,      
      Duration,
      Status,
      CreatedBy,
      CreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      _BaseEntity,
      _Customer,
      _TravelItem : redirected to composition child Z980_C_TravelItem
}
