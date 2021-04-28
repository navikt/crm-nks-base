({
    ctiLoaded: function (component, event, helper) {
        console.log('CTI LOADED!');
        component.set('v.ctiLoaded', true);
    },

    simulateCall: function (component, event, helper) {
        let identType = component.get('v.identType');
        let identifier = component.get('v.identifier');
        let fnr = '';
        let orgnr = '';

        if (identType == 'PERSON_IDENT') {
            fnr = identifier;
        } else {
            orgnr = identifier;
        }

        console.log('IDENT TYPE: ' + identType);
        console.log('IDENTIFIER: ' + identifier);

        let callback = function (response) {
            console.log(JSON.stringify(response, null, 2));
        };
        sforce.opencti.screenPop({
            type: sforce.opencti.SCREENPOP_TYPE.FLOW,
            params: {
                flowDevName: 'NKS_Inbound_Call',
                flowArgs: [
                    { name: 'fnr', type: 'String', value: fnr },
                    { name: 'orgnr', type: 'String', value: orgnr }
                ]
            },
            callback: callback
        });
    }
});
