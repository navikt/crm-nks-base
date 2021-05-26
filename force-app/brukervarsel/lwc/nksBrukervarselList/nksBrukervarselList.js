import { LightningElement, api, track, wire } from 'lwc';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import getBrukerVarsel from '@salesforce/apex/NKS_BrukervarselController.getBrukerVarselFromActorId';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.Name';

export default class NksBrukervarselList extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;
    showHeader = false;
    personId; //Salesforce ID to the person record
    personIdent;
    wireFields = [this.objectApiName + '.Id'];
    @track notifications = [];

    get showNotifications() {
        return notifications.length > 0;
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
        fields: [PERSON_IDENT_FIELD]
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            this.personIdent = getFieldValue(data, PERSON_IDENT_FIELD);
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ error, data }) {
        if (this.relationshipField && this.objectApiName) {
            this.getRelatedRecordId(this.relationshipField, this.objectApiName);
        }
    }

    @wire(getBrukerVarsel, {
        actorId: '$personIdent'
    })
    wiredVarsel({ error, data }) {
        if (data) {
            this.notifications = data;
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
