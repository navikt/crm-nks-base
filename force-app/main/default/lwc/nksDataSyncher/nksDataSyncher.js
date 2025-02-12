import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { publish, MessageContext } from 'lightning/messageService';
import DATA_SYNC_CHANNEL from '@salesforce/messageChannel/DataSyncChannel__c';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import syncBankAccountNumber from '@salesforce/apex/NKS_DataSynchController.doBankAccountNumberSync';
import { syncActorOppgaver } from 'c/crmOppgaveSyncher';
import { resolve } from 'c/nksComponentsUtils';

import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.Name';
import PERSON_ACTORID_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';
import PERSON_ACCOUNT_FIELD from '@salesforce/schema/Person__c.CRM_Account__c';

const SYNC_STATUS = {
    SYNCING: 'SYNCING',
    SYNCED: 'SYNCED',
    ERROR: 'ERROR'
};
export default class NksDataSyncher extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;

    syncStatuses = [];
    personId;
    initialized = false;
    synced = false;

    wireFields = [this.objectApiName + '.Id'];
    personFields = [PERSON_ACTORID_FIELD, PERSON_IDENT_FIELD, PERSON_ACCOUNT_FIELD];

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        //Initial synch performed in connected callback to prevent boxcaring due to many events triggered at the same time.
        this.initializeSync();
    }

    initializeSync() {
        this.addSyncStatus('bankAccount', 'Bankkontonummer', SYNC_STATUS.SYNCING);
        this.addSyncStatus('oppgave', 'Oppgave', SYNC_STATUS.SYNCING);
        this.getRelatedRecordId();
        this.initialized = true;
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
            //Not called in wire context before initial synch has been done through connectedCallback
            if (this.initialized && this.relationshipField && this.objectApiName) {
                this.getRelatedRecordId();
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
                this.startSynch(personIdent, personActorId, personAccountId);
            }
        }
        if (error) {
            console.log('Problem getting person information: ', JSON.stringify(error, null, 2));
        }
    }

    async startSynch(personIdent, personActorId, eventName = 'e.force:refreshView') {
        try {
            this.synced = false;
            await Promise.all([this.syncBankAccountNumber(personIdent), this.syncOppgave(personActorId)]);
            this.synced = true;
            const refreshEvent = new CustomEvent(eventName);
            this.dispatchEvent(refreshEvent);

            // e.force:refreshView only works for standard components
            // Notify other custom components that callout is complete to refresh data
            publish(this.messageContext, DATA_SYNC_CHANNEL, { status: 'SYNC_COMPLETE' });
        } catch (error) {
            console.error('Problem synching bankAccountNumber/oppgave: ', JSON.stringify(error, null, 2));
        }
    }

    async syncOppgave(personActorId) {
        if (this.getSyncStatus('oppgave') !== SYNC_STATUS.SYNCING) return;

        try {
            await syncActorOppgaver(personActorId);
            this.setSyncStatus('oppgave', SYNC_STATUS.SYNCED);
        } catch (error) {
            this.setSyncStatus('oppgave', SYNC_STATUS.ERROR);
            console.error('Error in syncOppgave:', JSON.stringify(error, null, 2));
            throw new Error('Error syncing oppgave: ' + error.message);
        }
    }

    async syncBankAccountNumber(ident) {
        if (this.getSyncStatus('bankAccount') !== SYNC_STATUS.SYNCING) return;

        try {
            await syncBankAccountNumber({ ident: ident });
            this.setSyncStatus('bankAccount', SYNC_STATUS.SYNCED);
        } catch (error) {
            this.setSyncStatus('bankAccount', SYNC_STATUS.ERROR);
            console.error('Error in syncBankAccountNumber:', JSON.stringify(error, null, 2));
            throw new Error('Error syncing bank account number: ' + error.message);
        }
    }

    getRelatedRecordId() {
        if (!this.recordId || !this.relationshipField || !this.objectApiName) return;

        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: this.relationshipField,
            objectApiName: this.objectApiName
        })
            .then((record) => {
                const resolvedPersonId = resolve(this.relationshipField, record);
                //Only update the wired attribute if it is indeed changed
                if (this.personId !== resolvedPersonId) {
                    this.setSyncStatus('bankAccount', SYNC_STATUS.SYNCING);
                    this.setSyncStatus('oppgave', SYNC_STATUS.SYNCING);
                    this.personId = resolvedPersonId;
                }
            })
            .catch((error) => {
                console.log('Problem getting related record: ', JSON.stringify(error, null, 2));
            });
    }

    addSyncStatus(name, label, status) {
        let syncStatus = this.getSyncStatus(name);

        if (syncStatus) {
            syncStatus.label = label;
            syncStatus.status = status;
        } else {
            syncStatus = this.getNewSyncStatus(name, label, status);
            this.syncStatuses.push(syncStatus);
        }

        this.calculateSyncStatus(syncStatus);
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
        let syncStatus = this.getSyncStatus(name);
        syncStatus.status = status;
        if (syncStatus) {
            this.calculateSyncStatus(syncStatus);
        }
    }

    calculateSyncStatus(syncStatus) {
        syncStatus.isSyncing = syncStatus.status === SYNC_STATUS.SYNCING;
        syncStatus.isSynced = syncStatus.status === SYNC_STATUS.SYNCED;
        syncStatus.isError = syncStatus.status === SYNC_STATUS.ERROR;
    }

    getSyncStatus(name) {
        return this.syncStatuses.find((element) => element.name === name);
    }
}
