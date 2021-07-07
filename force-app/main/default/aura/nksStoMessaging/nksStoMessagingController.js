({
    closeModal: function (component, event, helper) {
        component.set('v.showPanel', false);
    },

    handleToolbarAction: function (component, event, helper) {
        const flowName = event.getParam('flowName');
        component.set('v.showPanel', true);
        console.log('FLOW NAME: ' + flowName);
        let flowInputs = [
            {
                name: 'recordId',
                type: 'String',
                value: component.get('v.recordId')
            }
        ];

        const flow = component.find('panelFlow');
        flow.startFlow(flowName, flowInputs);
    }
});
