import { LightningElement, api } from 'lwc';
import CONVERSATION_NOTE_NEW_LABEL from '@salesforce/label/c.NKS_New_Conversation_Note';

const FLOW_API_NAME = 'Conversation_Note_Journal_From_Case';

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

    handleFlowButtonClicked(event) {
        if (this.journalAndShare && event.detail === FLOW_API_NAME) {
            this._journalConversation = true;
        }
    }
}
