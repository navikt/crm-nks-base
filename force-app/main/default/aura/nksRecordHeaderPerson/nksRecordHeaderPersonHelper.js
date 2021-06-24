({
    getAllQuickActionButtons: function (cmp) {
        let actions = [];
        let sObjectName = cmp.get('v.sObjectName');
        let recordId = cmp.get('v.recordId');

        cmp.get('v.quickActionsInput').forEach((quickAction) =>
            actions.push({
                actionName: 'Person' + sObjectName + '.' + quickAction,
                recordId: recordId,
                type: 'QuickAction'
            })
        );

        cmp.set('v.quickActions', actions);
    },

    setAge: function (cmp) {
        //let dateOfBirth = cmp.get('v.personRecord.INT_DateOfBirth__c');
        let dateOfBirth = cmp.get('v.accountRecord.CRM_Person__r.INT_DateOfBirth__c');
        if (dateOfBirth) {
            dateOfBirth = new Date(dateOfBirth);
            let age = null;
            let today = new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate());
            age =
                today.getFullYear() -
                dateOfBirth.getFullYear() -
                (this.dayOfYear(today) >= this.dayOfYear(dateOfBirth) ? 0 : 1);
            cmp.set('v.personAge', age);
        }
    },

    setGenderIcon: function (cmp) {
        let gender = 'neutral';
        switch (cmp.get('v.accountRecord.CRM_Person__r.INT_Sex__c')) {
            case 'Mann':
                gender = 'male';
                break;
            case 'Kvinne':
                gender = 'female';
                break;
        }

        cmp.set('v.genderIcon', gender);
    },

    dayOfYear: function dayOfYear(d) {
        return Math.floor((d - new Date(d.getFullYear(), 0, 0)) / 1000 / 60 / 60 / 24);
    },

    copyTextHelper: function (cmp, event, text) {
        // Create an hidden input
        var hiddenInput = document.createElement('input');
        // passed text into the input
        hiddenInput.setAttribute('value', text);
        // Append the hiddenInput input to the body
        document.body.appendChild(hiddenInput);
        // select the content
        hiddenInput.select();
        // Execute the copy command
        document.execCommand('copy');
        // Remove the input from the body after copy text
        document.body.removeChild(hiddenInput);
    },

    getAccountId: function (cmp) {
        let action = cmp.get('c.getRelatedRecord');
        action.setParams({
            parentId: cmp.get('v.recordId'),
            relationshipField: cmp.get('v.relationshipField'),
            objectApiName: cmp.get('v.sObjectName')
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === 'SUCCESS') {
                let accountId = this.resolve(cmp.get('v.relationshipField'), response.getReturnValue());
                cmp.set('v.accountId', accountId);
                cmp.find('accountRecordLoader').reloadRecord(true, function () {
                    console.log('accountRecordLoader callback');
                });
            } else if (state === 'INCOMPLETE') {
                // do something
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                        console.log('Error message: ' + errors[0].message);
                    }
                } else {
                    console.log('Unknown error');
                }
            }
        });
        $A.enqueueAction(action);
    },

    // getPersonId: function (cmp) {
    //     console.log('GET PERSON ID');
    //     let action = cmp.get('c.getRelatedRecord');
    //     action.setParams({
    //         parentId: cmp.get('v.recordId'),
    //         relationshipField: cmp.get('v.relationshipField'),
    //         objectApiName: cmp.get('v.sObjectName')
    //     });
    //     action.setCallback(this, function (response) {
    //         let state = response.getState();
    //         if (state === 'SUCCESS') {
    //             let personId = this.resolve(cmp.get('v.relationshipField'), response.getReturnValue());
    //             cmp.set('v.personId', personId);
    //             cmp.find('personRecordLoader').reloadRecord(true, function () {
    //                 console.log('personRecordLoader callback');
    //             });
    //         } else if (state === 'INCOMPLETE') {
    //             // do something
    //         } else if (state === 'ERROR') {
    //             var errors = response.getError();
    //             if (errors) {
    //                 if (errors[0] && errors[0].message) {
    //                     // log the error passed in to AuraHandledException
    //                     console.log('Error message: ' + errors[0].message);
    //                 }
    //             } else {
    //                 console.log('Unknown error');
    //             }
    //         }
    //     });
    //     $A.enqueueAction(action);
    // },

    resolve: function (path, obj) {
        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || self);
    }
});
