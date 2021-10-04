import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.Name';
import GENDER_FIELD from '@salesforce/schema/Person__c.INT_Sex__c';
import AGE_FIELD from '@salesforce/schema/Person__c.CRM_Age__c';
import CITIZENSHIP_FIELD from '@salesforce/schema/Person__c.INT_Citizenships__c';
import MARITAL_STATUS_FIELD from '@salesforce/schema/Person__c.INT_MaritalStatus__c';
import BANK_ACCOUNT_NUMBER_FIELD from '@salesforce/schema/Person__c.INT_BankAccountNumber__c';
import NAV_ICONS from '@salesforce/resourceUrl/NKS_navIcons';

export default class NksPersonHeader extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;
    @api showPersonBadges = false;
    showAll = false;
    isLoaded = false;
    personId;
    personIdent;
    gender;
    age;
    citizenship;
    maritalStatus;
    bankAccountNumber;
    wireFields;
    @track errorMessages = [];

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
    }

    get showNotifications() {
        return this.notifications.length > 0;
    }

    get showErrors() {
        return this.errorMessages.length > 0;
    }

    get genderIcon() {
        switch (this.gender) {
            case 'Mann':
                return 'MaleFilled';
            case 'Kvinne':
                return 'FemaleFilled';
        }
        return 'NeutralFilled';
    }

    get genderIconSrc() {
        return NAV_ICONS + '/' + this.genderIcon + '.svg#' + this.genderIcon;
    }

    get genderIconClass() {
        return this.genderIcon;
    }

    handleCopyIdent() {
        var hiddenInput = document.createElement('input');
        hiddenInput.value = this.personIdent;
        document.body.appendChild(hiddenInput);
        hiddenInput.focus();
        hiddenInput.select();
        try {
            var successful = document.execCommand('copy');
            var msg = successful ? 'successful' : 'unsuccessful';
            console.log('Copying text command was ' + msg);
        } catch (err) {
            console.log('Oops, unable to copy');
        }

        document.body.removeChild(hiddenInput);
    }

    getRelatedRecordId(relationshipField, objectApiName) {
        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: relationshipField,
            objectApiName: objectApiName
        })
            .then((record) => {
                this.personId = this.resolve(relationshipField, record);
            })
            .catch((error) => {
                this.addError(error);
            });
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: [
            PERSON_IDENT_FIELD,
            GENDER_FIELD,
            AGE_FIELD,
            CITIZENSHIP_FIELD,
            MARITAL_STATUS_FIELD,
            BANK_ACCOUNT_NUMBER_FIELD
        ]
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            this.personIdent = getFieldValue(data, PERSON_IDENT_FIELD);
            this.gender = getFieldValue(data, GENDER_FIELD);
            this.age = getFieldValue(data, AGE_FIELD);
            this.citizenship = getFieldValue(data, CITIZENSHIP_FIELD);
            this.maritalStatus = getFieldValue(data, MARITAL_STATUS_FIELD);
            this.bankAccountNumber = getFieldValue(data, BANK_ACCOUNT_NUMBER_FIELD);
        }
        if (error) {
            this.addError(error);
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
            if (this.relationshipField && this.objectApiName) {
                this.getRelatedRecordId(this.relationshipField, this.objectApiName);
            }
        }
        if (error) {
            this.addError(error);
        }
    }

    showAllNotifications() {
        this.showAll = true;
    }

    addError(error) {
        this.isLoaded = true;
        if (Array.isArray(error.body)) {
            this.errorMessages = this.errorMessages.concat(error.body.map((e) => e.message));
        } else if (error.body && typeof error.body.message === 'string') {
            this.errorMessages.push(error.body.message);
        } else {
            this.errorMessages.push(error.body);
        }
    }

    /**
     * Retrieves the value from the given object's data path
     * @param {data path} path
     * @param {JS object} obj
     */
    resolve(path, obj) {
        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || self);
    }
}
