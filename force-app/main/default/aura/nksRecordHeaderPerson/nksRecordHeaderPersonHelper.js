({
    setFlowButtons: function (cmp) {
        if (cmp.get('v.flowActionString')) {
            cmp.set('v.flowActions', JSON.parse(cmp.get('v.flowActionString')));
        }
    },

    getAge: function (dateOfBirth) {
        if (dateOfBirth) {
            let today = new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate());
            return (
                today.getFullYear() -
                new Date(dateOfBirth).getFullYear() -
                (this.dayOfYear(today) >= this.dayOfYear(new Date(dateOfBirth)) ? 0 : 1)
            );
        }
        return null;
    },

    setGenderIcon: function (cmp) {
        let gender;
        switch (cmp.get('v.accountRecord.CRM_Person__r.INT_Sex__c')) {
            case 'Mann':
                gender = 'male';
                break;
            case 'Kvinne':
                gender = 'female';
                break;
            default:
                gender = 'neutral';
        }

        cmp.set('v.genderIcon', gender);
    },

    setBrukerName: function (cmp) {
        let brukerName = 'Ukjent bruker';
        let age = null;
        if (cmp.get('v.accountRecord.CRM_Person__r.Name')) {
            brukerName = cmp.get('v.accountRecord.CRM_Person__r.NKS_Full_Name__c');
            age = this.getAge(cmp.get('v.accountRecord.CRM_Person__r.INT_DateOfBirth__c'));
        } else if (cmp.get('v.accountRecord.Name')) {
            brukerName = cmp.get('v.accountRecord.Name');
        }

        brukerName += age ? ' (' + age + ')' : '';

        cmp.set('v.nameLabel', brukerName);
    },

    dayOfYear: function dayOfYear(d) {
        return Math.floor((d - new Date(d.getFullYear(), 0, 0)) / 1000 / 60 / 60 / 24);
    },

    copyTextHelper: function (text) {
        let hiddenInput = document.createElement('input');
        // eslint-disable-next-line @locker/locker/distorted-element-set-attribute
        hiddenInput.setAttribute('value', text);
        document.body.appendChild(hiddenInput);
        hiddenInput.select();
        // eslint-disable-next-line @locker/locker/distorted-document-exec-command
        document.execCommand('copy');
        document.body.removeChild(hiddenInput);
    },

    resolve: function (path, obj) {
        if (typeof path !== 'string') {
            throw new Error('Path must be a string');
        }
        const parts = path.split('.');
        const result = parts.reduce(function (prev, curr) {
            return prev ? prev[curr] : undefined;
        }, obj || {});

        return result !== undefined ? result : null;
    }
});
