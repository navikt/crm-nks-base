import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import TEMPORARY_ADDRESS from '@salesforce/schema/Person__c.INT_TemporaryAddress__c';
import TEMPORARY_ZIP_CODE from '@salesforce/schema/Person__c.INT_TemporaryZipCode__c';
import TEMPORARY_COUNTRY_CODE from '@salesforce/schema/Person__c.INT_TemporaryCountryCode__c';
import TEMPORARY_MUNICIPALITY_NUMBER from '@salesforce/schema/Person__c.INT_TemporaryMunicipalityNumber__c';

export default class NksBostedAddress extends LightningElement {
    @api relationshipField;
    @api objectApiName;
    @api recordId;
    personId;
    address;
    zipCode;
    countryCode;
    municipalityNumber;
    open = false;

    connectedCallback() {
        if (this.relationshipField != null && this.relationshipField !== '') {
            this.getRelatedRecordId(this.relationshipField, this.objectApiName);
        }
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
        fields: [TEMPORARY_ADDRESS, TEMPORARY_COUNTRY_CODE, TEMPORARY_MUNICIPALITY_NUMBER, TEMPORARY_ZIP_CODE]
    })
    wiredRecord({ error, data }) {
        if (error) {
            console.log(error);
        } else if (data) {
            this.address = getFieldValue(data, TEMPORARY_ADDRESS);
            this.zipCode = getFieldValue(data, TEMPORARY_ZIP_CODE);
            this.countryCode = getFieldValue(data, TEMPORARY_COUNTRY_CODE);
            this.municipalityNumber = getFieldValue(data, TEMPORARY_MUNICIPALITY_NUMBER);
        }
    }

    get iconName() {
        return this.open ? 'utility:chevrondown' : 'utility:chevronright';
    }

    onclickHandler() {
        this.open = !this.open;
    }

    /*
     * HELPER FUNCTIONS
     */

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
