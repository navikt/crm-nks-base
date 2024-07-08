import { LightningElement, api, wire, track } from 'lwc';
import getReverseRelatedRecord from '@salesforce/apex/NksRecordInfoController.getReverseRelatedRecord';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CONVERSATION_NOTE_OBJECT from '@salesforce/schema/Conversation_Note__c';
import CHANGE_USER_LABEL from '@salesforce/label/c.NKS_Change_User';
import CREATE_TASK_LABEL from '@salesforce/label/c.NKS_Create_NAV_Task';
import PERSON_ACTORID_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';
import { publishToAmplitude } from 'c/amplitude';
import { handleShowNotifications } from 'c/nksButtonContainerUtils';
import CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL from '@salesforce/messageChannel/conversationNoteNotifications__c';
import { subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';

export default class NksConversationNoteDetails extends LightningElement {
    @api recordId;
    @api objectApiName;

    readAccessToPerson = false;
    dataShowing;
    notes = [];
    expanded = true;
    changeUserLabel = CHANGE_USER_LABEL;
    createTaskLabel = CREATE_TASK_LABEL;
    subscription = null;
    personId;
    wireFields;

    connectedCallback() {
        this.wireFields = [`${this.objectApiName}.Id`];
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    @wire(MessageContext)
    messageContext;

    @wire(getObjectInfo, { objectApiName: CONVERSATION_NOTE_OBJECT })
    objectInfo;

    @wire(getReverseRelatedRecord, {
        parentId: '$recordId',
        queryFields: 'Id, CRM_Conversation_Note__c, createddate, CRM_Theme__r.Name, CRM_Theme_Group__r.Name',
        objectApiName: 'Conversation_Note__c',
        relationshipField: 'CRM_Case__c',
        ordering: 'createddate asc'
    })
    wiredData(result) {
        this._wiredRecord = result;
        const { data, error } = result;
        if (data) {
            this.notes = data.map((x) => {
                return { ...x, name: x.CRM_Theme__r ? x.CRM_Theme__r?.Name : x.CRM_Theme_Group__r?.Name };
            });
        } else if (error) {
            console.log(error);
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
            if (this.objectApiName) {
                this.getRelatedRecordId('Account.CRM_Person__c', this.objectApiName);
            }
        }else if (error) {
            console.error(error);
        }
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: PERSON_ACTORID_FIELD
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            const actorId = getFieldValue(data, PERSON_ACTORID_FIELD);
            this.readAccessToPerson = actorId ? true : false;
        } else if (error) {
            console.error(error);
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
            })
            .catch((error) => {
                console.error(error);
            });
    }

    resolve(path, obj) {
        if (typeof path !== 'string') {
            throw new Error('Path must be a string');
        }

        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || {});
    }

    get recordLabel() {
        return this.objectInfo?.data?.label || 'Samtalereferat';
    }

    get inputVariables() {
        return [{ name: 'recordId', type: 'String', value: this.recordId }];
    }

    get reverseExpanded() {
        return !this.expanded;
    }

    get sectionClasses() {
        return `slds-section slds-var-p-horizontal_medium slds-var-p-top_small slds-m-vertical_none ${
            this.expanded ? 'slds-is-open' : ''
        }`;
    }

    get hasCNotes() {
        return this.notes != null && this.notes.length > 0;
    }

    get notificationBoxTemplate() {
        return this.template.querySelector('c-nks-notification-box');
    }

    get flowButtonLabel() {
        if(this.readAccessToPerson) {
            return this.changeUserLabel;
        } else {
            return this.createTaskLabel;
        }
    }

    get flowApiName() {
        if(this.readAccessToPerson) {
            return 'NKS_Case_Change_Account';
        } else {
            return 'NKS_Case_Send_NAV_Task_v_2';
        }
    }

    handleStatusChange(event) {
        const { status, outputVariables } = event.detail;

        if (
            status === 'FINISHED' &&
            outputVariables?.some((output) => output.objectType === 'Conversation_Note__c' && output.value !== null)
        ) {
            publishToAmplitude('Conversation Note Created');
            refreshApex(this._wiredRecord);
            handleShowNotifications('journal_conversation', outputVariables, this.notificationBoxTemplate, true);
        }
    }

    handleChange(event) {
        if (event.detail) {
            const { value } = event.detail;
            let message = {
                eventType: 'ThemeCategorization',
                properties: { value: value }
            };
            message.eventType +=
                value === 'GENERELL_SAK' || value === 'FAGSAK' ? ' - Sakstype endret' : ' - Theme/Gjelder changed';
            publishToAmplitude('ThemeCategorization', { value: value });
        }
    }

    handleExpandClick() {
        this.expanded = !this.expanded;
    }

    subscribeToMessageChannel() {
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(
            this.messageContext,
            CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL,
            (message) => this.handleMessage(message),
            { scope: APPLICATION_SCOPE }
        );
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(message) {
        if (this.recordId === message.recordId) {
            handleShowNotifications(message.flowApiName, message.outputVariables, this.notificationBoxTemplate);
        }
    }
}
