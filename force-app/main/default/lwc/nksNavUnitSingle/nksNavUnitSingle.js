import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getNavUnit from '@salesforce/apex/NKS_NavUnitSingleController.findUnit';
import getContactInformation from '@salesforce/apex/NKS_NavUnitSingleController.getContactInformation';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';

export default class NksNavUnitSingle extends LightningElement {
    @api recordId; // The record id
    @api objectApiName; // The object api name
    @api relationField; // Points to either the Person__c.Id or a field containging a unit number
    @api type; // If based on person location or unit
    @api allSectionsOpenOnLoad = false; // If all sections should be open when the component loads
    @api numCols = 2; // Number of columns for the displayed fields
    @api cardLayout = false; // If true, use the card layout, if not use box layout
    @api boxLayout = false;

    @track navUnit; // The nav unit
    @track contactInformation; // The nav unit contact information

    unitLookupValue;
    unitNumber;
    wireFields;
    @track errors = [];
    isLoaded = false;
    noLayout = false;

    connectedCallback() {
        this.setAttribute('title', 'NAV Enhet');
        this.wireFields = [this.objectApiName + '.Id'];

        if (!this.cardLayout && !this.boxLayout) {
            this.noLayout = true;
        }
    }

    get isError() {
        return this.errors.length > 0;
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
            this.isLoaded = false;
            this.getRelatedRecordUnit(this.relationField, this.objectApiName);
        }

        if (error) {
            this.setErrorMessage(error, 'caught');
            this.isLoaded = true;
        }
    }

    getRelatedRecordUnit(relationshipField, objectApiName) {
        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: relationshipField,
            objectApiName: objectApiName
        })
            .then((record) => {
                let relationshipFieldValue = this.resolve(relationshipField, record);
                this.unitLookupValue = relationshipFieldValue;
            })
            .catch((error) => {
                this.setErrorMessage(error, 'caughtError');
            });
    }

    @wire(getNavUnit, { value: '$unitLookupValue', type: '$type' }) wiredGetNavUnit(value) {
        this.wiredNavUnit = value;
        const { data, error } = this.wiredNavUnit;
        if (data) {
            this.navUnit = data;
            this.unitNumber = data.enhetNr;
            this.isLoaded = true;
        }

        if (error) {
            this.setErrorMessage(error, 'caughtError');
            this.isLoaded = true;
        }
    }

    @wire(getContactInformation, { unitNumber: '$unitNumber' }) wiredGetContactInformation(value) {
        this.wiredContactInformation = value;
        const { data, error } = this.wiredContactInformation;
        if (data) {
            this.contactInformation = data;
            this.isLoaded = true;
        }

        if (error) {
            this.setErrorMessage(error, 'caught');
            this.isLoaded = true;
        }
    }

    setErrorMessage(err, type) {
        type = err.body && type === 'caughtError' ? 'fetchResponseError' : type;
        switch (type) {
            case 'fetchResponseError':
                if (Array.isArray(err.body)) {
                    this.errors = this.errors.concat(err.body.map((e) => e.message));
                } else if (typeof err.body.message === 'string') {
                    let errorType = err.body.exceptionType ? err.body.exceptionType + ': ' : '';
                    this.errors.push(errorType + err.body.message);
                }
                break;
            case 'journalpostError':
                let errorString = '';
                if (err.status) {
                    errorString = err.status + ' ';
                }
                errorString += err.error + ' - ' + err.message;
                this.errors.push(errorString);
                break;
            case 'caughtError':
                this.errors.push('Ukjent feil: ' + err.message);
                break;
            default:
                this.errors.push('Ukjent feil: ' + err);
                break;
        }
    }

    resolve(path, obj) {
        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || self);
    }
}
