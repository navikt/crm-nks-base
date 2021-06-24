({
    setFlowButtons: function (cmp) {
        const flowButtonString = cmp.get('v.flowActionString');

        if (flowButtonString) {
            cmp.set('v.flowActions', JSON.parse(flowButtonString));
        }
    },

    setAge: function (cmp) {
        if (cmp.get('v.accountRecord.CRM_Person__r.INT_DateOfBirth__c')) {
            const dateOfBirth = new Date(cmp.get('v.accountRecord.CRM_Person__r.INT_DateOfBirth__c'));
            let today = new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate());
            const age =
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
        var hiddenInput = document.createElement('input');
        hiddenInput.setAttribute('value', text);
        document.body.appendChild(hiddenInput);
        hiddenInput.select();
        document.execCommand('copy');
        document.body.removeChild(hiddenInput);
    },

    getAccountId: function (cmp) {
        let action = cmp.get('c.getRelatedRecord');
        cmp.set('v.isLoaded', false);
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
                    cmp.set('v.isLoaded', true);
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

    resolve: function (path, obj) {
        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || self);
    }
});
