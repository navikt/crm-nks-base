## LWC: Dynamic Related List

LWC for displaying a related list with filter options based on inputs definbed in js-meta.xml.

# Attributes

| Name      | Type   | Access | Required | Description                                             |
| :-------- | :----- | :----- | :------- | :------------------------------------------------------ |
| listTitle | String | global | false    | Title of the list to be displayed in the header section |
| iconName | String | global | false    | Icon name on the format required from standard [lightning-icon](https://developer.salesforce.com/docs/component-library/bundle/lightning-icon/example) |
| headerColor | String | global | false    | Picklist in app builder config setting the background color of the header |
| relatedObjectApiName | String | global | true    | Object API name for records in the related list |
| relationField | String | global | true    | API name of field relating the records to the parent where the component is displayed |
| parentRelationField | String | global | true    | API name of field relation the records to the parent where the component is displayed |
| relationField | String | global | true    | Object API name for records in the related list |
| filterConditions | String | global | false    | Optional filter conditions written as standard query conditions (i.e. Name != 'TEST') |
