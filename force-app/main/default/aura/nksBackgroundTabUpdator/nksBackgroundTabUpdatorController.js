({
    onTabCreated: function (component, event, helper) {
        var newTabId = event.getParam('tabId');
        var workspace = component.find('workspace');

        workspace.getAllTabInfo().then(function (response) {
            if (response.length === 1) {
                workspace
                    .isSubtab({
                        tabId: newTabId
                    })
                    .then(function (response) {
                        if (!response) {
                            workspace.focusTab({
                                tabId: newTabId
                            });
                        }
                    });
            }
        });

        workspace
            .getTabInfo({
                tabId: newTabId
            })
            .then(function (response) {
                var action = component.get('c.getTabName');
                action.setParams({ recordId: response.recordId });
                action.setCallback(this, function (data) {
                    if (
                        data.getReturnValue() != null &&
                        data.getReturnValue().length > 0
                    ) {
                        workspace.setTabLabel({
                            tabId: newTabId,
                            label: data.getReturnValue()
                        });
                    }
                });
                $A.enqueueAction(action);
            });
    },

    doInit: function (component, event, helper) {
        var omniAPI = component.find('omniToolkit');
        var action = component.get('c.getOnlineId');
        action.setCallback(this, function (data) {
            if (
                data.getReturnValue() != null &&
                data.getReturnValue().length > 0
            ) {
                var poll = setInterval(function () {
                    omniAPI
                        .login({ statusId: data.getReturnValue() })
                        .then(function (result) {
                            clearInterval(poll);
                        })
                        .catch(function (error) {
                            console.log(error);
                        });
                }, 2000);
            }
        });
        $A.enqueueAction(action);
    }
});
