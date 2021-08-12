import { LightningElement, api, track, wire } from 'lwc';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import getBrukerVarsel from '@salesforce/apex/NKS_BrukervarselController.getBrukerVarselFromActorId';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';

export default class NksBrukervarselList extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;
    showAll = false;
    personId;
    personIdent;
    wireFields;
    isLoaded = false;
    @track notifications = [];
    @track errorMessages = [];
    fromDate;
    toDate;

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
        this.setDefaultDates();
    }

    get showNotifications() {
        return this.notifications.length > 0;
    }

    get filteredNotificationList() {
        if (this.notifications.length < 1) {
            return [];
        }

        return this.showAll ? this.notifications : this.notifications.slice(0, 1);
    }

    get numberOfNotifications() {
        return this.notifications ? this.notifications.length : 0;
    }

    get showErrors() {
        return this.errorMessages.length > 0;
    }

    get showFooter() {
        return this.showAll === false && this.notifications.length > 1;
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
        fields: [PERSON_IDENT_FIELD]
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            this.personIdent = getFieldValue(data, PERSON_IDENT_FIELD);
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

    @wire(getBrukerVarsel, {
        actorId: '$personIdent',
        fromDate: '$fromDate',
        toDate: '$toDate'
    })
    wiredVarsel({ error, data }) {
        if (data) {
            this.errorMessages = [];
            this.notifications = data;
            this.isLoaded = true;
        }

        if (error) {
            this.addError(error);
        }
    }

    setDefaultDates() {
        const today = new Date();
        this.toDate = today.toISOString().split('T')[0];
        today.setMonth(today.getMonth() - 1);
        this.fromDate = today.toISOString().split('T')[0];
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
