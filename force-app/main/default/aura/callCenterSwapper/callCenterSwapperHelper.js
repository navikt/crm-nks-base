({
    switchCallCenter: function (component, targetCallCenterId) {
        var action = component.get('c.swapCallCenter');
        action.setParams({
            callcenterId: targetCallCenterId
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var previousCallCenterId = component.get('v.currentCallCenterId');
                component.set('v.currentCallCenterId', targetCallCenterId);
                component.set('v.isUnrecognizedCenter', false);
                component.set('v.isDisabled', false);
                component.set('v.showRefreshButton', previousCallCenterId !== targetCallCenterId);
                var puzzelId = component.get('v.puzzelCallCenterId');
                component.set('v.isToggled', targetCallCenterId === puzzelId);
                console.log('Call center switched successfully.');
            } else {
                console.error('Failed to switch call center: ' + response.getError());
            }
        });
        $A.enqueueAction(action);
    }
});
