({
    ctiLoaded: function (component, event, helper) {
        console.log('CTI LOADED!');
        component.set('v.ctiLoaded', true);
    },

    simulateCall: function (component, event, helper) {
        let identifier = component.get('v.identifier');

        let callback = function (response) {
            console.log(JSON.stringify(response, null, 2));
        };
        sforce.opencti.screenPop({
            type: sforce.opencti.SCREENPOP_TYPE.FLOW,
            params: {
                flowDevName: 'NKS_Inbound_Call',
                flowArgs: [{ name: 'sfdc_case_id', type: 'String', value: identifier }]
            },
            callback: callback
        });
    }
});
