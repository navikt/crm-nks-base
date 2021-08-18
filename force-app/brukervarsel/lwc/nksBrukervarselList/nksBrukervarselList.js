import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
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
    wiredBrukerVarsel;

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
        /*
        * sort list descending by date in sisteVarselutsendelse
        * if missing, then looking for the latest date in varselListe.sendt
        */
        let n = [...this.notifications].sort(
            (a,b) => 
                {
                    let reduceToMaxDate = (c,d) => ( c.sendt > d.sendt ) ? c : d ;
                    let getLatestDate = (e) => 
                        (e.sisteVarselutsendelse != null) ? 
                        e.sisteVarselutsendelse : 
                        e.varselListe.reduce(reduceToMaxDate).sendt;
                    let ad = getLatestDate(a);
                    let bd = getLatestDate(b);     
                    return (ad < bd) - (ad > bd);
                }
        ); 
        return this.showAll ? n : n.slice(0,1);
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
    wiredGetBrukerVarsel(value) {
        this.wiredBrukerVarsel = value;
        this.setWiredBrukerVarsel();
    }
    setWiredBrukerVarsel() {
        const {error, data} = this.wiredBrukerVarsel;
        if (data) {
            this.errorMessages = [];
            this.notifications = data;
            this.isLoaded = true;
        }

        if (error) {
            this.addError(error);
        }
    }

    refreshNotificationList() {
        this.isLoaded = false;
        return refreshApex(this.wiredBrukerVarsel).then(() => {
            this.setWiredBrukerVarsel();
        });
    }

    onDateFilterChange(event) {
        const eventName = event.target.name;
        const eventValue = event.target.value;

        switch (eventName) {
            case 'fromDate':
                this.fromDate = eventValue;
                if ( this.fromDate > this.toDate) this.toDate = this.fromDate;
                break;
            case 'toDate':
                this.toDate = eventValue;
                if ( this.toDate < this.fromDate) this.fromDate = this.toDate;
                break;
            default:
                break;
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
