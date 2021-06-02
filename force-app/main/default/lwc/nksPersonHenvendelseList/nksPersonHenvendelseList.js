import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getHenvendelsesListe from '@salesforce/apex/NKS_HenvendelseListController.getPersonHenvendelser';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import PERSON_ACTOR_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';

export default class NksPersonHenvendelseList extends LightningElement {
    @api recordId; // Id from record page (From UiRecordAPI)
    @api objectApiName; // Value from UiRecordAPI
    @api relationshipField;
    personId;
    personIdent;
    showAll = false;
    wireFields;
    @track threadList = [];

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
        this.getRelatedRecordId(this.relationshipField, this.objectApiName);
    }

    get showThreadList() {
        return this.threadList.length > 0;
    }

    get filteredThreadList() {
        if (this.threadList.length < 1) {
            return [];
        }

        return this.showAll ? this.ThreadList : this.threadList.slice(0, 1);
    }

    get numberOfThreads() {
        return this.threadList ? this.threadList.length : 0;
    }

    showAllThreads() {
        this.showAll = true;
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
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: [PERSON_ACTOR_FIELD]
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            this.personIdent = getFieldValue(data, PERSON_ACTOR_FIELD);
        }
        if (error) {
            //this.error = true;
            //this.setErrorMessage(error, 'caughtError');
        }
    }

    @wire(getHenvendelsesListe, {
        personIdent: '$personIdent'
    })
    wiredPersonHenvendelser({ error, data }) {
        if (data) {
            this.threadList = data;
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
                if (null == this.personId) {
                    this.personIdent = null;
                }
            })
            .catch((error) => {
                this.setErrorMessage(error, 'caughtError');
            });
    }

    resolve(path, obj) {
        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || self);
    }
}
