import { LightningElement, api, wire, track } from 'lwc';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import synchConversationNotes from '@salesforce/apex/NKS_DataSynchController.doHenvendelseSynch';
import syncBankAccountNumber from '@salesforce/apex/NKS_DataSynchController.doBankAccountNumberSync';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.Name';
import PERSON_ACTORID_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';
import PERSON_ACCOUNT_FIELD from '@salesforce/schema/Person__c.CRM_Account__c';
import syncActorOppgaver from 'c/crmOppgaveSyncher';

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

    connectedCallback() {
        //Initial synch performed in connected callback to prevent boxcaring due to many events triggered at the same time.
        this.addSyncStatus('bankAccount', 'Bankkontonummer', syncStatus.SYNCING);
        this.addSyncStatus('henvendelse', 'Henvendelse', syncStatus.SYNCING);
        this.addSyncStatus('oppgave', 'Oppgave', syncStatus.SYNCING);
        this.getRelatedRecordId(this.relationshipField, this.objectApiName);
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
            console.log(JSON.stringify(error, null, 2));
        }
    }

    async doSynch(personIdent, personActorId, personAccountId) {
        await Promise.all([
            this.bankAccountNumberSync(personIdent),
            this.oppgaveSync(personActorId)
            //this.conversationNoteSynch(personIdent, personAccountId) Disabling this for henvendelse migration
        ]);
        this.initialized = true;
        eval("$A.get('e.force:refreshView').fire();"); //As getRecordNotifyChange does not support complete rerender of related lists, the aura hack is used
    }

    oppgaveSync(personActorId) {
        return new Promise(async (resolve, reject) => {
            if (this.getSyncStatus('oppgave').status != syncStatus.SYNCING) {
                return resolve();
            }
            syncActorOppgaver(personActorId)
                .then(() => {
                    this.setSyncStatus('oppgave', syncStatus.SYNCED);
                })
                .catch((error) => {
                    this.setSyncStatus('oppgave', syncStatus.ERROR);
                    console.log(JSON.stringify(error, null, 2));
                })
                .finally(() => {
                    resolve();
                });
        });
    }

    conversationNoteSynch(personIdent, personAccountId) {
        return new Promise(async (resolve, reject) => {
            if (this.getSyncStatus('henvendelse').status != syncStatus.SYNCING) {
                return resolve();
            }
            synchConversationNotes({ personIdent: personIdent, accountId: personAccountId })
                .then(() => {
                    this.setSyncStatus('henvendelse', syncStatus.SYNCED);
                })
                .catch((error) => {
                    this.setSyncStatus('henvendelse', syncStatus.ERROR);
                    console.log(JSON.stringify(error, null, 2));
                })
                .finally(() => {
                    resolve();
                });
        });
    }

    bankAccountNumberSync(ident) {
        return new Promise(async (resolve, reject) => {
            if (this.getSyncStatus('bankAccount').status != syncStatus.SYNCING) {
                return resolve();
            }
            syncBankAccountNumber({ ident: ident })
                .then((result) => {
                    this.setSyncStatus('bankAccount', syncStatus.SYNCED);
                })
                .catch((error) => {
                    this.setSyncStatus('bankAccount', syncStatus.ERROR);
                    console.error(JSON.stringify(error, null, 2));
                })
                .finally(() => {
                    resolve();
                });
        });
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
                    this.setSyncStatus('henvendelse', syncStatus.SYNCING);
                    this.personId = resolvedPersonId;
                }
            })
            .catch((error) => {
                console.log(JSON.stringify(error, null, 2));
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
        ss.isSyncing = ss.status === syncStatus.SYNCING ? true : false;
        ss.isSynced = ss.status === syncStatus.SYNCED ? true : false;
        ss.isError = ss.status === syncStatus.ERROR ? true : false;
    }

    getSyncStatus(name) {
        return this.syncStatuses.find((element) => element.name === name);
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
