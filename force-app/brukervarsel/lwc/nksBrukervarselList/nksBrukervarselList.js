import { LightningElement, api, track, wire } from 'lwc';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import getBrukernotifikasjon from '@salesforce/apex/NKS_BrukervarselController.getBrukerNotifikasjonFromIdent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PERSON_ACTOR_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.Name';
import { publishToAmplitude } from 'c/amplitude';

export default class NksBrukervarselList extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;

    @track notifications = [];
    @track filteredNotificationList = [];
    @track errorMessages = [];

    showAll = false;
    personId;
    wireFields;
    isLoaded = false;
    wiredPerson = null;
    fromDate;
    toDate;
    wiredBrukerVarsel;

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
        this.setDefaultDates();
    }

    get showNotifications() {
        return this.filteredNotificationList.length > 0;
    }

    get maxDate() {
        return new Date().toISOString().split('T')[0];
    }

    get numberOfNotifications() {
        return this.filteredNotificationList ? this.filteredNotificationList.length : 0;
    }

    get showErrors() {
        return this.errorMessages.length > 0;
    }

    get showFooter() {
        return this.showAll === false && this.filteredNotificationList.length > 1;
    }

    get personIdent() {
        return getFieldValue(this.wiredPerson.data, PERSON_IDENT_FIELD);
    }

    get personActorId() {
        return getFieldValue(this.wiredPerson.data, PERSON_ACTOR_FIELD);
    }

    get notificationList() {
        return this.showAll ? this.filteredNotificationList : this.filteredNotificationList.slice(0, 1);
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
        fields: [PERSON_ACTOR_FIELD, PERSON_IDENT_FIELD]
    })
    wiredPersonInfo(value) {
        const { error, data } = value;
        this.wiredPerson = value;

        if (data) {
            this.getNotifications();
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

    getNotifications() {
        this.isLoaded = false;
        this.errorMessages = [];

        getBrukernotifikasjon({ fnr: this.personIdent })
            .then((data) => {
                this.notifications = data;
                this.filterNotificationList();
                this.isLoaded = true;
            })
            .catch((error) => {
                this.addError(error);
                this.isLoaded = true;
            });
    }

    filterNotificationList() {
        let reduceToMaxDate = (c, d) => (c.sendt > d.sendt ? c : d);
        let getLatestDate = (e) => {
            return e.sisteVarselutsendelse != null
                ? e.sisteVarselutsendelse
                : e.varselListe.reduce(reduceToMaxDate).sendt;
        };

        /*
         * sort list descending by date in sisteVarselutsendelse
         * if missing, then looking for the latest date in varselListe.sendt
         */
        let n = [...this.notifications]
            .filter(
                (notification) =>
                    getLatestDate(notification) >= this.fromDate && getLatestDate(notification) <= this.toDate
            )
            .sort((a, b) => {
                let ad = getLatestDate(a);
                let bd = getLatestDate(b);
                return (ad < bd) - (ad > bd);
            });

        this.filteredNotificationList = n;
    }

    refreshNotificationList() {
        this.isLoaded = false;
        this.getNotifications();
        publishToAmplitude('UN List', { type: 'Click on refresh button' });
    }

    onDateFilterChange(event) {
        const eventName = event.target.name;
        const eventValue = event.target.value;

        switch (eventName) {
            case 'fromDate':
                this.fromDate = eventValue;
                if (this.fromDate > this.toDate) this.toDate = this.fromDate;
                this.getNotifications();
                break;
            case 'toDate':
                this.toDate = eventValue;
                if (this.toDate < this.fromDate) this.fromDate = this.toDate;
                this.getNotifications();
                break;
            default:
                break;
        }
        publishToAmplitude('UN List', { type: 'Change date range' });
    }

    setDefaultDates() {
        const today = new Date();
        this.toDate = today.toISOString().split('T')[0];
        today.setMonth(today.getMonth() - 1);
        this.fromDate = today.toISOString().split('T')[0];
    }

    showAllNotifications() {
        this.showAll = true;
        this.filterNotificationList();
        publishToAmplitude('UN List', { type: 'Show all notifications' });
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
        if (typeof path !== 'string') {
            throw new Error('Path must be a string');
        }

        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || {});
    }
}
