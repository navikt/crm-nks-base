({
    invoke: function (component, event, helper) {
        let workspaceAPI = component.find('workspace');
        workspaceAPI
            .getFocusedTabInfo()
            .then((tabInfo) => {
                workspaceAPI
                    .closeTab({ tabId: tabInfo.tabId })
                    .then((response) => {
                        //Success
                    })
                    .catch((error) => {
                        console.log(JSON.stringify(error, null, 2));
                    });
            })
            .catch((error) => {
                console.log(JSON.stringify(error, null, 2));
            });
    }
});
