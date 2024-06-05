import { LightningElement, api, wire } from 'lwc';
import CONVERSATION_NOTE_NEW_LABEL from '@salesforce/label/c.NKS_New_Conversation_Note';
import { callGetCommonCode, getOutputVariableValue } from 'c/nksButtonContainerUtils';
import { subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL from '@salesforce/messageChannel/conversationNoteNotifications__c';

const FLOW_API_NAMES = {
    CREATE_NAV_TASK: 'NKS_Case_Send_NAV_Task',
    JOURNAL: 'Conversation_Note_Journal_From_Case'
};

export default class NksConversationNoteButtonContainer extends LightningElement {
    @api recordId;
    @api conversationNoteButtonLabel;
    @api journalAndShare = false;

    newConversationNote = CONVERSATION_NOTE_NEW_LABEL;
    _journalConversation;
    subscription = null;

    @api
    get journalConversation() {
        return this._journalConversation;
    }

    set journalConversation(value) {
        this._journalConversation = value;
    }

    get conversationNoteButtonVariant() {
        return this.conversationNoteButtonLabel === this.newConversationNote ? 'brand-outline' : 'brand';
    }

    get notificationBoxTemplate() {
        return this.template.querySelector('c-nks-notification-box');
    }

    @wire(MessageContext)
    messageContext;

    /*
    connectedCallback() {
        this.subscribeToMessageChannel();
    }*/

    renderedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
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
        this.notificationBoxTemplate.addNotification(
            'Samtalereferat er delt med bruker og saken er journalført',
            message.journalTheme
        );
    }

    handleFlowButtonClicked(event) {
        if (this.journalAndShare && event.detail === FLOW_API_NAMES.JOURNAL) {
            this._journalConversation = true;
        }
    }

    async handleFlowSucceeded(event) {
        const outputVariables = event.detail?.flowOutput;

        if (!outputVariables) {
            console.error('No output variables found in the event detail');
            return;
        }
        try {
            if (event.detail?.flowName === FLOW_API_NAMES.JOURNAL) {
                const selectedThemeId = getOutputVariableValue(outputVariables, 'Selected_Theme_SF_Id');
                let journalTheme = '';

                if (selectedThemeId) {
                    journalTheme = await callGetCommonCode(selectedThemeId);
                }

                this.notificationBoxTemplate.addNotification('Saken er journalført', journalTheme);
            } else if (event.detail?.flowName === FLOW_API_NAMES.CREATE_NAV_TASK) {
                const selectedThemeId = getOutputVariableValue(outputVariables, 'Selected_Theme_SF_Id');
                const unitName = getOutputVariableValue(outputVariables, 'Selected_Unit_Name');
                const unitNumber = getOutputVariableValue(outputVariables, 'Selected_Unit_Number');
                let navTaskTheme = '';

                if (selectedThemeId) {
                    navTaskTheme = await callGetCommonCode(selectedThemeId);
                }

                this.notificationBoxTemplate.addNotification(
                    'Oppgave opprettet',
                    `${navTaskTheme} Sendt til: ${unitNumber} ${unitName}`
                );
            }
        } catch (error) {
            console.error('Error handling flow succeeded event: ', error);
        }
    }
}
