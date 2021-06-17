import { LightningElement, api, wire } from 'lwc';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import synchConversationNotes from '@salesforce/apex/NKS_DataSynchController.doHenvendelseSynch';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.Name';
import PERSON_ACTORID_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';
import PERSON_ACCOUNT_FIELD from '@salesforce/schema/Person__c.CRM_Account__c';

export default class NksDataSyncher extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;
    wireFields = [this.objectApiName + '.Id'];
    personId;
    synchFinished = false;
    personFields = [PERSON_ACTORID_FIELD, PERSON_IDENT_FIELD, PERSON_ACCOUNT_FIELD];

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
        fields: '$personFields'
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            let personIdent = getFieldValue(data, PERSON_IDENT_FIELD);
            let personActorId = getFieldValue(data, PERSON_ACTORID_FIELD);
            let personAccountId = getFieldValue(data, PERSON_ACCOUNT_FIELD);

            this.doSynch(personIdent, personActorId, personAccountId);
        }
        if (error) {
            console.log(JSON.stringify(error, null, 2));
        }
    }

    async doSynch(personIdent, personActorId, personAccountId) {
        await this.conversationNoteSynch(personIdent, personAccountId);
        this.synchFinished = true;
        eval("$A.get('e.force:refreshView').fire();"); //As getRecordNotifyChange does not support complete rerender of related lists, the aura hack is used
    }

    conversationNoteSynch(personIdent, personAccountId) {
        return new Promise(async (resolve, reject) => {
            synchConversationNotes({ personIdent: personIdent, accountId: personAccountId })
                .then(() => {
                    //HURRAY!
                })
                .catch((error) => {
                    console.log(JSON.stringify(error, null, 2));
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
                    this.personId = resolvedPersonId;
                }
            })
            .catch((error) => {
                console.log(JSON.stringify(error, null, 2));
            });
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
