({
    invoke: function (component, event, helper) {
        var workspaceAPI = component.find('workspace');
        var recordId = component.get('v.recordId');
        workspaceAPI
            .openTab({
                pageReference: {
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: recordId,
                        actionName: 'view'
                    },
                    state: {}
                },
                focus: true
            })
            .then(function (response) {
                workspaceAPI
                    .getTabInfo({
                        tabId: response
                    })
                    .then(function (tabInfo) {
                        console.log('The recordId for this tab is: ' + tabInfo.recordId);
                    });
            })
            .catch(function (error) {
                console.log(error);
            });
    }
});
