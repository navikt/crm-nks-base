({
    doInit: function (cmp, event, helper) {
        helper.setFlowButtons(cmp);
        // eslint-disable-next-line @salesforce/aura/ecma-intrinsics, compat/compat
        cmp.set('v.recordFields', Array.from(new Set(['Id', cmp.get('v.relationshipField')])));
        cmp.set('v.loadRecord', true);
    },

    handleFlowActionOnClick: function (cmp, event) {
        cmp.find('flowModal').openModal(event.getSource().get('v.label'), event.getSource().get('v.name'));
    },

    handleCopyIdent: function (cmp, event, helper) {
        helper.copyTextHelper(cmp.get('v.accountRecord.CRM_Person__r.Name'));
    },

    onRecordUpdated: function (cmp, event, helper) {
        if (event.getParams()) {
            cmp.set('v.accountId', helper.resolve(cmp.get('v.relationshipField'), cmp.get('v.record')));
            cmp.find('accountRecordLoader').reloadRecord(true, function () {});
        }
    },

    onAccountRecordUpdated: function (cmp, event, helper) {
        if (event.getParams()) {
            helper.setGenderIcon(cmp);
            helper.setBrukerName(cmp);
            cmp.set('v.isLoaded', true);
        }
    },

    reloadRecord: function (cmp) {
        cmp.find('recordLoader').reloadRecord(true, function () {});
    }
});
