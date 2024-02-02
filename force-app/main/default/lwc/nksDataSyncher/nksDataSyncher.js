import { LightningElement, api, wire, track } from 'lwc';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import syncBankAccountNumber from '@salesforce/apex/NKS_DataSynchController.doBankAccountNumberSync';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.Name';
import PERSON_ACTORID_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';
import PERSON_ACCOUNT_FIELD from '@salesforce/schema/Person__c.CRM_Account__c';
import { syncActorOppgaver } from 'c/crmOppgaveSyncher';

const syncStatus = {
    SYNCING: 'SYNCING',
    SYNCED: 'SYNCED',
    ERROR: 'ERROR'
};
export default class NksDataSyncher extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;

    @track syncStatuses = [];

    wireFields = [this.objectApiName + '.Id'];
    personId;
    personFields = [PERSON_ACTORID_FIELD, PERSON_IDENT_FIELD, PERSON_ACCOUNT_FIELD];
    initialized = false;
    synced = false;

    connectedCallback() {
        //Initial synch performed in connected callback to prevent boxcaring due to many events triggered at the same time.
        this.addSyncStatus('bankAccount', 'Bankkontonummer', syncStatus.SYNCING);
        this.addSyncStatus('oppgave', 'Oppgave', syncStatus.SYNCING);
        this.getRelatedRecordId(this.relationshipField, this.objectApiName);
        this.initialized = true;
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
            //Not called in wire context before initial synch has been done through connectedCallback
            if (this.initialized === true && this.relationshipField && this.objectApiName) {
                this.getRelatedRecordId(this.relationshipField, this.objectApiName);
            }
        } else if (error) {
            console.log('Problme getting record: ', JSON.stringify(error, null, 2));
        }
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: '$personFields'
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            let personIdent = getFieldValue(data, PERSON_IDENT_FIELD);
            let personActorId = getFieldValue(data, PERSON_ACTORID_FIELD);
            let personAccountId = getFieldValue(data, PERSON_ACCOUNT_FIELD);

            if (personIdent) {
                this.doSynch(personIdent, personActorId, personAccountId);
            }
        }
        if (error) {
            console.log('Problem getting person information: ', JSON.stringify(error, null, 2));
        }
    }

    async doSynch(personIdent, personActorId, eventName = 'e.force:refreshView') {
        try {
            this.synced = false;
            await Promise.all([this.bankAccountNumberSync(personIdent), this.oppgaveSync(personActorId)]);
            this.synced = true;
            const refreshEvent = new CustomEvent(eventName);
            this.dispatchEvent(refreshEvent);
        } catch (error) {
            console.error('Problem synching bankAccountNumber/oppgave: ', JSON.stringify(error, null, 2));
        }
    }

    async oppgaveSync(personActorId) {
        try {
            const syncStatusObj = this.getSyncStatus('oppgave');
            if (syncStatusObj.status !== syncStatus.SYNCING) {
                return;
            }

            await syncActorOppgaver(personActorId);
            this.setSyncStatus('oppgave', syncStatus.SYNCED);
        } catch (error) {
            this.setSyncStatus('oppgave', syncStatus.ERROR);
            console.error('Error in oppgaveSync:', JSON.stringify(error, null, 2));
            throw new Error('Error syncing oppgave: ' + error.message);
        }
    }

    async bankAccountNumberSync(ident) {
        try {
            const syncStatusObj = this.getSyncStatus('bankAccount');
            if (syncStatusObj.status !== syncStatus.SYNCING) {
                return;
            }

            await syncBankAccountNumber({ ident: ident });
            this.setSyncStatus('bankAccount', syncStatus.SYNCED);
        } catch (error) {
            this.setSyncStatus('bankAccount', syncStatus.ERROR);
            console.error('Error in bankAccountNumberSync:', JSON.stringify(error, null, 2));
            throw new Error('Error syncing bank account number: ' + error.message);
        }
    }

    getRelatedRecordId(relationshipField, objectApiName) {
        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: relationshipField,
            objectApiName: objectApiName
        })
            .then((record) => {
                let resolvedPersonId = this.resolve(relationshipField, record);
                //Only update the wired attribute if it is indeed changed
                if (this.personId !== resolvedPersonId) {
                    this.setSyncStatus('bankAccount', syncStatus.SYNCING);
                    this.setSyncStatus('oppgave', syncStatus.SYNCING);
                    this.personId = resolvedPersonId;
                }
            })
            .catch((error) => {
                console.log('Problem getting related record: ', JSON.stringify(error, null, 2));
            });
    }

    addSyncStatus(name, label, status) {
        let ss = this.getSyncStatus(name);

        if (ss) {
            ss.label = label;
            ss.status = status;
        } else {
            ss = this.getNewSyncStatus(name, label, status);
            this.syncStatuses.push(ss);
        }

        this.calculateSyncStatus(ss);
    }

    getNewSyncStatus(name, label, status) {
        return {
            name: name,
            label: label,
            status: status,
            isSyncing: false,
            isSynced: false,
            isError: false
        };
    }

    setSyncStatus(name, status) {
        let ss = this.getSyncStatus(name);
        ss.status = status;
        if (ss) {
            this.calculateSyncStatus(ss);
        }
    }

    calculateSyncStatus(ss) {
        ss.isSyncing = ss.status === syncStatus.SYNCING;
        ss.isSynced = ss.status === syncStatus.SYNCED;
        ss.isError = ss.status === syncStatus.ERROR;
    }

    getSyncStatus(name) {
        return this.syncStatuses.find((element) => element.name === name);
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
