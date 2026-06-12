@EndUserText.label: 'Flight Travel Item (Projection)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
define view entity Z980_C_TravelItem
//  provider contract transactional_query
  as projection on Z980_R_TRAVELITEM
{
  key ItemUuid,
      AgencyId,
      TravelId,

      @Consumption.valueHelpDefinition:
              [ { entity: { name:    '/DMO/I_Carrier_StdVH',
                            element: 'AirlineID'
                          }
                }
              ]
      CarrierId,

      @Consumption.valueHelpDefinition:
               [ { entity: { name:    '/DMO/I_Connection_StdVH',
                             element: 'ConnectionID'
                           },
                   additionalBinding:
                        [ { localElement: 'CarrierId',
                                 element: 'AirlineID',
                                   usage: #FILTER_AND_RESULT
                          }
                        ],
                   label: 'Value Help by Connection'
                 },
                 { entity: { name:    '/DMO/I_Flight_StdVH',
                             element: 'ConnectionID'
                           },
                   additionalBinding:
                        [ { localElement: 'CarrierId',
                            element:      'AirlineID',
                            usage:        #FILTER_AND_RESULT
                          },
                          { localElement: 'FlightDate',
                            element:      'FlightDate',
                            usage:         #RESULT
                         }
                       ],
                   label: 'Value Help by Flight',
                   qualifier: 'Secondary Value help'
                 }
               ]
      ConnectionId,

      @Consumption.valueHelpDefinition:
           [ { entity: { name:    '/DMO/I_Flight_StdVH',
                         element: 'FlightDate'
                       },
               additionalBinding:
                    [ { localElement: 'CarrierId',
                        element:      'AirlineID',
                        usage:         #FILTER_AND_RESULT
                      },
                      { localElement: 'ConnectionID',
                        element:      'ConnectionID',
                        usage:        #RESULT
                      }
                    ]
             }
           ]
      FlightDate,
      BookingId,
      PassengerFirstName,
      PassengerLastName,
      CreatedBy,
      CreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      /* Associations */
      _Travel : redirected to parent Z980_C_TRAVEL
}
