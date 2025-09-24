({
    onTabCreated: function (component, event, helper) {
        const workspaceAPI = component.find('workspace');
        const tabId = event.getParam('tabId');

        workspaceAPI
            .getTabInfo({ tabId })
            .then((tabInfo) => helper.saveCaseTabInfo(tabId, tabInfo))
            .catch((error) => {
                console.error('Error getting tabInfo for tabId:', tabId, error);
            });
    },

    onTabClosed: function (component, event, helper) {
        const closedTabId = event.getParam('tabId');
        const launcher = component.find('launcher');

        const info = helper.getTabInfo(closedTabId);

        if (
            info &&
            info.recordId &&
            !info.isSubtab &&
            info.objectApiName === 'Case' &&
            launcher &&
            typeof launcher.openModal === 'function'
        ) {
            launcher.openModal(info.recordId);
        }

        helper.removeTabInfo(closedTabId);
    }
});
