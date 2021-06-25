import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getHenvendelsesListe from '@salesforce/apex/NKS_HenvendelseListController.getPersonHenvendelser';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import PERSON_NAME_FIELD from '@salesforce/schema/Person__c.Name';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';

export default class NksPersonHenvendelseList extends LightningElement {
    @api recordId; // Id from record page (From UiRecordAPI)
    @api objectApiName; // Value from UiRecordAPI
    @api relationshipField;
    personId;
    personIdent;
    showAll = false;
    wireFields;
    isLoaded = false;
    @track threadList = [];
    @track errorMessages = [];
    wiredPersonHenvendelser;

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
    }

    get showThreadList() {
        return this.threadList.length > 0;
    }

    get filteredThreadList() {
        if (this.threadList.length < 1) {
            return [];
        }

        return this.showAll ? this.threadList : this.threadList.slice(0, 1);
    }

    get numberOfThreads() {
        return this.threadList ? this.threadList.length : 0;
    }

    get showErrors() {
        return this.errorMessages.length > 0;
    }

    get showFooter() {
        return this.showAll === false && this.threadList && this.threadList.length > 1;
    }

    setShowAllThreads() {
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
        if (error) {
            this.addError(error);
        }
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: [PERSON_NAME_FIELD, PERSON_IDENT_FIELD]
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            this.personIdent = getFieldValue(data, PERSON_NAME_FIELD);
        }
        if (error) {
            this.addError(error);
        }
    }

    @wire(getHenvendelsesListe, {
        personIdent: '$personIdent'
    })
    wiredGetHenvendelsesListe(value) {
        this.wiredPersonHenvendelser = value;
        this.setWiredPersonHenvendelser();
    }

    setWiredPersonHenvendelser() {
        const { error, data } = this.wiredPersonHenvendelser;

        if (data) {
            this.errorMessages = [];
            this.threadList = data;
            this.isLoaded = true;
        }
        if (error) {
            this.addError(error);
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
                this.addError(error, 'caughtError');
            });
    }

    refreshThreadList() {
        this.isLoaded = false;
        return refreshApex(this.wiredPersonHenvendelser).then(() => {
            this.setWiredPersonHenvendelser();
        });
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

    resolve(path, obj) {
        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || self);
    }
}
