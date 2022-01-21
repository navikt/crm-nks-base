({
    handleArticleLoad: function (component, event, helper) {
        var eventParams = event.getParams();
        if (eventParams.changeType === 'LOADED') {
            const summary = component.get('v.articleRecord.NKS_Summary__c');
            helper.addToClipBoard(component, summary);
        } else if (eventParams.changeType === 'CHANGED') {
            // record is changed
        } else if (eventParams.changeType === 'REMOVED') {
            // record is deleted
        } else if (eventParams.changeType === 'ERROR') {
            // there’s an error while loading, saving, or deleting the record
            helper.displayToast('Error', 'error', 'Kunne ikke kopiere sammendrag');
        }
    }
});
