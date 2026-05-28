({
    init: function (component, event, helper) {
        var callCentersAction = component.get('c.getCallCenters');
        callCentersAction.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var callCenters = response.getReturnValue();

                var demoId = callCenters['Demo Call Center Adapter'];
                var puzzelId = callCenters['Puzzel Agent Adapter New'];

                if (!demoId || !puzzelId) {
                    component.set('v.errorMessage', 'Unable to load call centers. Please contact support.');
                    component.set('v.isDisabled', true);
                    return;
                }

                component.set('v.demoCallCenterId', demoId);
                component.set('v.puzzelCallCenterId', puzzelId);
            } else {
                component.set('v.errorMessage', 'Failed to retrieve call centers.');
                component.set('v.isDisabled', true);
            }
        });
        $A.enqueueAction(callCentersAction);

        var currentCCAction = component.get('c.getCurrentCallCenter');
        currentCCAction.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var currentCallCenterId = response.getReturnValue();
                component.set('v.currentCallCenterId', currentCallCenterId);

                var puzzelId = component.get('v.puzzelCallCenterId');
                var demoId = component.get('v.demoCallCenterId');

                if (currentCallCenterId === puzzelId) {
                    component.set('v.isToggled', true);
                } else if (currentCallCenterId === demoId) {
                    component.set('v.isToggled', false);
                } else {
                    component.set('v.isUnrecognizedCenter', true);
                    component.set('v.isDisabled', true);
                    var getCCNameAction = component.get('c.getCallCenterName');
                    getCCNameAction.setParams({
                        callCenterId: currentCallCenterId
                    });
                    getCCNameAction.setCallback(this, function (nameResponse) {
                        var nameState = nameResponse.getState();
                        if (nameState === 'SUCCESS') {
                            component.set('v.currentCallCenterName', nameResponse.getReturnValue());
                        } else {
                            component.set('v.currentCallCenterName', currentCallCenterId);
                        }
                    });
                    $A.enqueueAction(getCCNameAction);
                }
            } else {
                component.set('v.errorMessage', 'Failed to retrieve current call center.');
                component.set('v.isDisabled', true);
            }
        });
        $A.enqueueAction(currentCCAction);
    },

    handleToggleChanged: function (component, event, helper) {
        var isToggled = event.getSource().get('v.checked');
        var targetCallCenterId = isToggled
            ? component.get('v.puzzelCallCenterId')
            : component.get('v.demoCallCenterId');

        helper.switchCallCenter(component, targetCallCenterId);
    },

    handleSwitchToDemo: function (component, event, helper) {
        var targetCallCenterId = component.get('v.demoCallCenterId');
        helper.switchCallCenter(component, targetCallCenterId);
    },

    handleSwitchToPuzzel: function (component, event, helper) {
        var targetCallCenterId = component.get('v.puzzelCallCenterId');
        helper.switchCallCenter(component, targetCallCenterId);
    }
});
