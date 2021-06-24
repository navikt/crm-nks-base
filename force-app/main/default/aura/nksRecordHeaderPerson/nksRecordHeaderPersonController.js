({
    doInit: function (cmp, event, helper) {
        console.log('************************************************************');
        console.log('DO INIT');
        helper.getAllQuickActionButtons(cmp);
        //helper.getPersonId(cmp);
        helper.getAccountId(cmp);
    },

    handleQuickActionOnClick: function (cmp, event, helper) {
        var actionAPI = cmp.find('quickActionAPI');
        let actionName = event.getSource().get('v.name');
        let recordId = cmp.get('v.recordId');

        let args = { actionName: 'Account.NewCase' }; //{ actionName: actionName, recordId: recordId, type: 'QuickAction', entityName: 'Account' };
        actionAPI
            .invokeAction(args)
            .then(function (result) {
                console.log('Available Fields are ', JSON.stringify(result));
                //actionAPI.invokeAction(args);
            })
            .catch(function (e) {
                if (e.errors) {
                    console.log('Action Field Log Errors are ', e.errors);
                    console.error('Full error is ', JSON.stringify(e));
                }
            });
        // actionAPI
        //     .getCustomAction(args)
        //     .then(function (customAction) {
        //         if (customAction) {
        //             customAction.subscribe(function (data) {
        //                 console.log(data);
        //             });
        //             customAction.publish({
        //                 message: 'Hello Custom Action',
        //                 Param1: 'This is a parameter'
        //             });
        //         }
        //     })
        //     .catch(function (error) {
        //         console.log(error.errors);
        //     });
    },

    handleCopyIdent: function (cmp, event, helper) {
        //helper.copyTextHelper(cmp, event, cmp.get('v.personRecord.Name'));
        helper.copyTextHelper(cmp, event, cmp.get('v.accountRecord.CRM_Person__r.Name'));
    },

    onAccountRecordUpdated: function (cmp, event, helper) {
        var eventParams = event.getParams();

        if (eventParams.changeType === 'LOADED') {
            helper.setAge(cmp);
            helper.setGenderIcon(cmp);
        }
        //  else if(eventParams.changeType === "CHANGED") {

        //  } else if(eventParams.changeType === "REMOVED") {

        //  } else if(eventParams.changeType === "ERROR") {

        //  }
    },

    onPersonRecordUpdated: function (cmp, event, helper) {
        var eventParams = event.getParams();

        if (eventParams.changeType === 'LOADED') {
            helper.setAge(cmp);
            helper.setGenderIcon(cmp);
        }
        //  else if(eventParams.changeType === "CHANGED") {

        //  } else if(eventParams.changeType === "REMOVED") {

        //  } else if(eventParams.changeType === "ERROR") {

        //  }
    }
});
