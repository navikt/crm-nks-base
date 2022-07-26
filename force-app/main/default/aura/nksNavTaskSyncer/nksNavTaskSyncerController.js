({
    doInit: function (component, event, helper) {
        //Call apex to initiate sync activity
        let syncAction = component.get('c.syncOpenAndAssigned');
        syncAction.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                //Successful sync
                $A.get('e.force:refreshView').fire();
            } else {
                console.log('Error performing oppgave sync: ' + JSON.stringify(response.getError()));
            }
        });

        $A.enqueueAction(syncAction);
    }
});
