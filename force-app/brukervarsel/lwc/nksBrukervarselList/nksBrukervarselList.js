import { LightningElement, api, track, wire } from 'lwc';
// import { refreshApex } from '@salesforce/apex';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import getBrukerVarsel from '@salesforce/apex/NKS_BrukervarselController.getBrukerVarselFromActorId';
import getBrukernotifikasjon from '@salesforce/apex/NKS_BrukervarselController.getBrukerNotifikasjonFromIdent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PERSON_ACTOR_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.Name';

export default class NksBrukervarselList extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;
    showAll = false;
    personId;
    wireFields;
    isLoaded = false;
    @track notifications = [];
    @track filteredNotificationList = [];

    wiredPerson = null;

    varsler = [];
    brukernotifikasjon = [];

    @track errorMessages = [];
    fromDate;
    toDate;
    wiredBrukerVarsel;
    usernotificationsLoaded = false;

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
        this.setDefaultDates();
    }

    get showNotifications() {
        return this.filteredNotificationList.length > 0;
    }

    filterNotificationList() {
        if (this.notifications.length < 1) {
            this.filteredNotificationList = [];
        }
        /*
         * sort list descending by date in sisteVarselutsendelse
         * if missing, then looking for the latest date in varselListe.sendt
         */
        let n = [...this.notifications].sort((a, b) => {
            let reduceToMaxDate = (c, d) => (c.sendt > d.sendt ? c : d);
            let getLatestDate = (e) => {
                return e.sisteVarselutsendelse != null
                    ? e.sisteVarselutsendelse
                    : e.varselListe.reduce(reduceToMaxDate).sendt;
            };
            let ad = getLatestDate(a);
            let bd = getLatestDate(b);
            return (ad < bd) - (ad > bd);
        });
        this.filteredNotificationList = this.showAll ? n : n.slice(0, 1);
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

    get personIdent() {
        return getFieldValue(this.wiredPerson.data, PERSON_IDENT_FIELD);
    }

    get personActorId() {
        return getFieldValue(this.wiredPerson.data, PERSON_ACTOR_FIELD);
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
            this.usernotificationsLoaded = false;
            this.brukernotifikasjon = [];
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
        this.varsler = [];

        const brukervarsler = new Promise((resolve, reject) => {
            getBrukerVarsel({
                actorId: this.personActorId,
                fromDate: this.fromDate,
                toDate: this.toDate
            })
                .then((data) => {
                    this.varsler = data;
                    resolve();
                })
                .catch((error) => {
                    this.addError(error);
                    reject();
                });
        });

        const brukernotifikasjoner = new Promise((resolve, reject) => {
            if (this.usernotificationsLoaded === true) {
                resolve();
            } else {
                getBrukernotifikasjon({ fnr: this.personIdent })
                    .then((data) => {
                        this.brukernotifikasjon = data;
                        this.usernotificationsLoaded = true;
                        resolve();
                    })
                    .catch((error) => {
                        this.addError(error);
                        reject();
                    });
            }
        });

        Promise.allSettled([brukervarsler, brukernotifikasjoner]).finally(() => {
            this.notifications = new Array().concat(this.varsler).concat(this.brukernotifikasjon);
            this.isLoaded = true;
            this.filterNotificationList();
        });
    }

    refreshNotificationList() {
        this.isLoaded = false;
        this.getNotifications();
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
