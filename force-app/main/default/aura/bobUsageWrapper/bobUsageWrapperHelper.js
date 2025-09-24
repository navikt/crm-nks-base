({
    getMap: function () {
        try {
            return JSON.parse(sessionStorage.getItem('tabInfoMap')) || {};
        } catch (e) {
            return {};
        }
    },

    setMap: function (map) {
        sessionStorage.setItem('tabInfoMap', JSON.stringify(map));
    },

    saveCaseTabInfo: function (tabId, tabInfo) {
        const objectApiName =
            tabInfo.pageReference && tabInfo.pageReference.attributes && tabInfo.pageReference.attributes.objectApiName
                ? tabInfo.pageReference.attributes.objectApiName
                : null;

        if (objectApiName !== 'Case') {
            return;
        }

        const map = this.getMap();
        const recordId =
            tabInfo.recordId ||
            (tabInfo.pageReference && tabInfo.pageReference.state && tabInfo.pageReference.state.recordId) ||
            null;

        map[tabId] = {
            isSubtab: !!tabInfo.isSubtab,
            objectApiName: objectApiName,
            recordId: recordId
        };

        this.setMap(map);
    },

    getTabInfo: function (tabId) {
        const map = this.getMap();
        return map[tabId];
    },

    removeTabInfo: function (tabId) {
        const map = this.getMap();
        if (map[tabId]) {
            delete map[tabId];
            this.setMap(map);
        }
    }
});
