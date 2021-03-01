({
    doInit: function (component, event, helper) {
        let buttonLabel = component.get('v.buttonLabel');
        //If the button label is a reference to a custom label, use the custom label reference, else fallback to the input value
        buttonLabel = helper.isLabelReference(component, buttonLabel)
            ? $A.getReference('$Label.c.' + buttonLabel)
            : buttonLabel;

        component.set('v.buttonLabel', buttonLabel);
    },

    toggleFlow: function (component, event, helper) {
        let showFlow = !component.get('v.showFlow');
        component.set('v.showFlow', showFlow);
        component.set('v.ariaExpanded', showFlow.toString()); //Aria attribute requires string

        if (showFlow) {
            const flow = component.find('flowData');
            const flowName = component.get('v.flowName');

            let input = [
                {
                    name: 'recordId',
                    type: 'String',
                    value: component.get('v.recordId')
                }
            ];

            flow.startFlow(flowName, input);
        }
    },

    flowStatusChange: function (component, event, helper) {
        let flowStatus = event.getParam('status');
        if (flowStatus === 'FINISHED' || flowStatus === 'FINISHED_SCREEN') {
            //Flow finished
        }
    }
});
