({
    onTabCreated: function (component, event) {
        const workspaceAPI = component.find('workspace');
        const tabId = event.getParam('tabId');

        workspaceAPI
            .getTabInfo({ tabId: tabId })
            .then(function (tabInfo) {
                const isSubtab = !!tabInfo.isSubtab;
                const objectApiName =
                    tabInfo.pageReference &&
                    tabInfo.pageReference.attributes &&
                    tabInfo.pageReference.attributes.objectApiName
                        ? tabInfo.pageReference.attributes.objectApiName
                        : null;
                const recordId =
                    tabInfo.recordId ||
                    (tabInfo.pageReference && tabInfo.pageReference.state && tabInfo.pageReference.state.recordId) ||
                    null;
                let map = {};
                try {
                    map = JSON.parse(sessionStorage.getItem('tabInfoMap')) || {};
                } catch (e) {
                    map = {};
                }

                map[tabId] = {
                    isSubtab: isSubtab,
                    objectApiName: objectApiName,
                    recordId: recordId
                };
                sessionStorage.setItem('tabInfoMap', JSON.stringify(map));
            })
            .catch(function (error) {
                console.error('Error getting tabInfo for tabId:', tabId, error);
            });
    },

    onTabClosed: function (component, event) {
        const closedTabId = event.getParam('tabId');
        const launcher = component.find('launcher');
        let map = {};
        try {
            map = JSON.parse(sessionStorage.getItem('tabInfoMap')) || {};
        } catch (e) {
            map = {};
        }
        const info = map[closedTabId];

        if (
            info &&
            info.recordId &&
            info.isSubtab === false &&
            info.objectApiName === 'Case' &&
            launcher &&
            typeof launcher.openModal === 'function'
        ) {
            launcher.openModal(info.recordId);
        }

        if (info) {
            delete map[closedTabId];
            sessionStorage.setItem('tabInfoMap', JSON.stringify(map));
        }
    }
});
