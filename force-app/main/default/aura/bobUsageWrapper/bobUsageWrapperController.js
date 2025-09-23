({
    onTabClosed: function (component, event) {
        var closedTabId = event.getParam('tabId');
        var workspaceAPI = component.find('workspace');
        const recordId = component.get('v.recordId');
        const launcher = component.find('launcher');

        // Work around to avoide opening modal for subtabs. If getTabInfo returns data, it is a subtab becuse a tab still exists.
        workspaceAPI.getTabInfo({ tabId: closedTabId }).catch(function () {
            if (recordId && recordId.startsWith('500') && launcher && typeof launcher.openModal === 'function') {
                launcher.openModal(recordId);
            }
        });
    }
});
