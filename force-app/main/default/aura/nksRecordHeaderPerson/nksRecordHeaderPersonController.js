({
    doInit: function (cmp, event, helper) {
        helper.setFlowButtons(cmp);
        helper.getAccountId(cmp);
    },

    handleFlowActionOnClick: function (cmp, event, helper) {
        cmp.find('flowModal').openModal(event.getSource().get('v.label'), event.getSource().get('v.name'));
    },

    handleCopyIdent: function (cmp, event, helper) {
        helper.copyTextHelper(cmp, event, cmp.get('v.accountRecord.CRM_Person__r.Name'));
    },

    onAccountRecordUpdated: function (cmp, event, helper) {
        var eventParams = event.getParams();

        if (eventParams.changeType === 'LOADED') {
            helper.setAge(cmp);
            helper.setGenderIcon(cmp);
        } else if (eventParams.changeType === 'CHANGED') {
            helper.setAge(cmp);
            helper.setGenderIcon(cmp);
        } else if (eventParams.changeType === 'REMOVED') {
            helper.setAge(cmp);
            helper.setGenderIcon(cmp);
        } else if (eventParams.changeType === 'ERROR') {
            helper.setAge(cmp);
            helper.setGenderIcon(cmp);
        }
    }
});
