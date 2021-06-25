({
    openModel: function (component, event, helper) {
        // Set isModalOpen attribute to true

        var params = event.getParam('arguments');
        if (params) {
            component.set('v.isModalOpen', true);
            component.set('v.modalAriaLabel', params.modalAriaLabel);

            const flow = component.find('flowData');

            let input = [
                {
                    name: 'recordId',
                    type: 'String',
                    value: component.get('v.recordId')
                }
            ];
            flow.startFlow(params.flowToOpen, input);
        }
    },

    closeModel: function (component, event, helper) {
        // Set isModalOpen attribute to false
        component.set('v.isModalOpen', false);
    },

    flowStatusChange: function (component, event, helper) {
        let flowStatus = event.getParam('status');
        if (flowStatus === 'FINISHED' || flowStatus === 'FINISHED_SCREEN') {
            component.set('v.isModalOpen', false);
            $A.enqueueAction(component.get('v.flowIsFinisedAction'));
        }
    }
});
