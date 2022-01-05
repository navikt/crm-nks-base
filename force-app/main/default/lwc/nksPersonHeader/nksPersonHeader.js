import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import FULL_NAME_FIELD from '@salesforce/schema/Person__c.CRM_FullName__c';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.Name';
import GENDER_FIELD from '@salesforce/schema/Person__c.INT_Sex__c';
import AGE_FIELD from '@salesforce/schema/Person__c.CRM_Age__c';
import CITIZENSHIP_FIELD from '@salesforce/schema/Person__c.INT_Citizenships__c';
import MARITAL_STATUS_FIELD from '@salesforce/schema/Person__c.INT_MaritalStatus__c';
import NAV_ICONS from '@salesforce/resourceUrl/NKS_navIcons';
import getHistorikk from '@salesforce/apex/NKS_HistorikkViewController.getHistorikk';

export default class NksPersonHeader extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;
    @api showPersonBadges = false;
    personId;
    fullName;
    personIdent;
    gender;
    age;
    citizenship;
    maritalStatus;
    wireFields;
    @api condition1;
    @api condition2;
    @api btnClick = false;
    @api btnShowFullmakt = false;
    @api fullmaktHistData;
    @track customclass = 'grey-icon';

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

    get condition1() {
        if (this.age && (this.citizenship || this.maritalStatus)) return true;
    }

    get condition2() {
        if (this.citizenship && this.maritalStatus) return true;
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
        } catch (error) {
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
                console.log(error);
            });
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: [FULL_NAME_FIELD, PERSON_IDENT_FIELD, GENDER_FIELD, AGE_FIELD, CITIZENSHIP_FIELD, MARITAL_STATUS_FIELD]
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            this.fullName = getFieldValue(data, FULL_NAME_FIELD);
            this.personIdent = getFieldValue(data, PERSON_IDENT_FIELD);
            this.gender = getFieldValue(data, GENDER_FIELD);
            this.age = getFieldValue(data, AGE_FIELD);
            this.citizenship = getFieldValue(data, CITIZENSHIP_FIELD);
            this.maritalStatus = getFieldValue(data, MARITAL_STATUS_FIELD);
        }
        if (error) {
            console.log(error);
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
            console.log(error);
        }
    }

    /*
     * To change the button color on click
     */
    handleFullmaktData() {
        if (!this.btnClick) {
            this.btnClick = true;
            this.customclass = 'blue-icon';
        } else if (this.btnClick) {
            this.btnClick = false;
            this.customclass = 'grey-icon';
        }
    }

    @wire(getHistorikk, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredHistorikk({ error, data }) {
        if (data) {
            this.fullmaktHistData = data;
            this.btnShowFullmakt = this.fullmaktHistData.length > 0;
        }
        if (error) {
            this.addError(error);
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
