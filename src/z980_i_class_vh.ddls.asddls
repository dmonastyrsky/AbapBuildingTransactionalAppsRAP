@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for Booking Class'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity Z980_I_CLASS_VH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name: 'Z980_CLASS_ID' )
{
  @UI.lineItem: [{ position: 10 }]
  @EndUserText.label: 'Class ID'  
  @ObjectModel.text.element: ['Description']
  key value_low as ClassID,

  @UI.lineItem: [{ position: 20 }]
  @EndUserText.label: 'Description'
  text as Description
}
where
  language = $session.system_language
