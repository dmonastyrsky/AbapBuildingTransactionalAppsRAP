extend view entity Z980_C_TravelItem with {
    @Consumption.valueHelpDefinition: [
    { entity: { name:    'Z980_I_CLASS_VH',
                element: 'ClassID' } } ]
    Item.ZZclassZIT as ZZclassZIT
}
