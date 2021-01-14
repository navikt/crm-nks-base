({
    onTabCreated: function (component, event, helper) {
        var newTabId = event.getParam('tabId');
        var workspace = component.find("workspace");
        workspace.getTabInfo({
            tabId: newTabId
        }).then(function (response) {
            var action = component.get("c.getTabName");
            action.setParams({ "recordId": response.recordId });
            action.setCallback(this, function (data) {
                if (data.getReturnValue().length > 0) {
                    console.log('teeRETURN' + data.getReturnValue());
                    workspace.setTabLabel({
                        tabId: newTabId,
                        label: data.getReturnValue(),
                    });
                }
            });
            $A.enqueueAction(action);
        });

    }
})