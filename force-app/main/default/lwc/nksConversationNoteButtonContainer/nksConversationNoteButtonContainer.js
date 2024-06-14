import { LightningElement, api, wire } from 'lwc';
import CONVERSATION_NOTE_NEW_LABEL from '@salesforce/label/c.NKS_New_Conversation_Note';
import CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL from '@salesforce/messageChannel/conversationNoteNotifications__c';
import { publish, MessageContext } from 'lightning/messageService';

const JOURNAL_FLOW_API_NAME = 'NKS_Conversation_Note_Journal_Case_v_2';

export default class NksConversationNoteButtonContainer extends LightningElement {
    @api recordId;
    @api conversationNoteButtonLabel;
    @api journalAndShare = false;

    newConversationNote = CONVERSATION_NOTE_NEW_LABEL;
    _journalConversation;

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

    @wire(MessageContext)
    messageContext;

    handleFlowButtonClicked(event) {
        if (this.journalAndShare && event.detail === JOURNAL_FLOW_API_NAME) {
            this._journalConversation = true;
        }
    }

    handleFlowSucceeded(event) {
        const flowApiName = event.detail?.flowName;
        const outputVariables = event.detail?.flowOutput;
        try {
            const payload = {
                flowApiName: flowApiName,
                outputVariables: outputVariables
            };
            publish(this.messageContext, CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL, payload);
        } catch (error) {
            console.error('Error publishing message on conversation note message channel: ', error);
        }
    }
}
