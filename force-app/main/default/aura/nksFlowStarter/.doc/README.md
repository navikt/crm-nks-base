## AURA: Flow Starter

Simple aura component allowing to start a flow on screen on button click

## Attributes

| Name      | Type   | Access | Required | Description                                             |
| :-------- | :----- | :----- | :------- | :------------------------------------------------------ |
| flowName | String | global | true    | API name of the flow to be started from the button |
| buttonLabel | String | global | false    | Label of the button to be displayed (Also supports adding the reference to custom label by API name) |
| buttonIcon | String | global | false    | Icon to be displayed. See https://www.lightningdesignsystem.com/icons/ |
| fullButtonWidth | String | global | false  | Boolean value to determine if the button should fill the whole container width|


## Usage

The component is supported for all lightning record pages and can initiate all screen flows who solely requires the record id as input.
