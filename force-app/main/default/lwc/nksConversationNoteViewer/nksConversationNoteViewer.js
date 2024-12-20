import { LightningElement, api, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import CONVERSATION_NOTE_FIELD from '@salesforce/schema/Conversation_Note__c.CRM_Conversation_Note__c';
import TIMELINE_NAME_FIELD from '@salesforce/schema/Conversation_Note__c.NKS_Timeline_Name__c';
import { handleShowNotifications } from 'c/nksComponentsUtils';

const CONVERSATION_NOTE_FIELDS = [CONVERSATION_NOTE_FIELD, TIMELINE_NAME_FIELD];

export default class NksConversationNoteViewer extends LightningElement {
    @api recordId;
    @api objectApiName;
    conversationNote;
    timelineName;
    apiName;
    activeFlowApiName;
    showFlow = false;
    conversationNoteSubscription = null;

    @wire(getRecord, { recordId: '$recordId', fields: CONVERSATION_NOTE_FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.conversationNote = getFieldValue(data, CONVERSATION_NOTE_FIELD);
            this.timelineName = getFieldValue(data, TIMELINE_NAME_FIELD);
        } else if (error) {
            console.error('Error fetching Conversation Note:', error);
        }
    }

    handleJournal() {
        this.openFlow('NKS_Conversation_Note_Journal_Case_v_2');
    }

    handleRedact() {
        this.openFlow('Conversation_Note_Set_Redaction');
    }

    handleCreateTask() {
        this.openFlow('STO_Conversation_Note_Send_NAV_Task');
    }

    openFlow(flowApiName) {
        this.showFlow = false;
        // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
        setTimeout(() => {
            this.activeFlowApiName = flowApiName;
            this.showFlow = true;
        }, 10);
    }

    handleFlowStatusChange(event) {
        const { status, outputVariables } = event.detail;
        if (status === 'FINISHED') {
            handleShowNotifications('journal_conversation', outputVariables, this.notificationBoxTemplate, true);
            this.showFlow = false;
        }
    }

    get inputVariables() {
        return [{ name: 'recordId', type: 'String', value: this.recordId }];
    }

    get notificationBoxTemplate() {
        return this.template.querySelector('c-nks-notification-box');
    }
}
