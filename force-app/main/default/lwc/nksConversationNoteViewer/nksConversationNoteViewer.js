import { LightningElement, api, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import CONVERSATION_NOTE_FIELD from '@salesforce/schema/Conversation_Note__c.CRM_Conversation_Note__c';
import THEME_GROUP_FIELD from '@salesforce/schema/Conversation_Note__c.CRM_Theme_Group_Name__c';
import IS_READ_FIELD from '@salesforce/schema/Conversation_Note__c.CRM_Is_Read_Formula__c';
import { handleShowNotifications } from 'c/nksComponentsUtils';
import { subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL from '@salesforce/messageChannel/conversationNoteNotifications__c';
import BUTTON_CONTAINER_NOTIFICATIONS_CHANNEL from '@salesforce/messageChannel/buttonContainerNotifications__c';

const CONVERSATION_NOTE_FIELDS = [CONVERSATION_NOTE_FIELD, THEME_GROUP_FIELD, IS_READ_FIELD];

export default class NksConversationNoteViewer extends LightningElement {
    @api recordId;
    @api objectApiName;
    conversationNote;
    themeGroup;
    isRead;
    apiName;
    activeFlowApiName;
    showFlow = false;
    conversationNoteSubscription = null;

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$recordId', fields: CONVERSATION_NOTE_FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.conversationNote = getFieldValue(data, CONVERSATION_NOTE_FIELD);
            this.themeGroup = getFieldValue(data, THEME_GROUP_FIELD);
            this.isRead = getFieldValue(data, IS_READ_FIELD);
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

    subscribeToMessageChannel() {
        if (!this.conversationNoteSubscription) {
            this.conversationNoteSubscription = subscribe(
                this.messageContext,
                CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }

        if (!this.buttonContainerSubscription) {
            this.buttonContainerSubscription = subscribe(
                this.messageContext,
                BUTTON_CONTAINER_NOTIFICATIONS_CHANNEL,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        if (this.conversationNoteSubscription) {
            unsubscribe(this.conversationNoteSubscription);
            this.conversationNoteSubscription = null;
        }

        if (this.buttonContainerSubscription) {
            unsubscribe(this.buttonContainerSubscription);
            this.buttonContainerSubscription = null;
        }
    }

    get getTitle() {
        return 'Samtalereferat ' + (this.themeGroup ? this.themeGroup : '') + ' - ' + (this.isRead ? this.isRead : '');
    }

    get inputVariables() {
        return [{ name: 'recordId', type: 'String', value: this.recordId }];
    }

    get notificationBoxTemplate() {
        return this.template.querySelector('c-nks-notification-box');
    }
}
