import { LightningElement, api } from 'lwc';
import CONVERSATION_NOTE_NEW_LABEL from '@salesforce/label/c.NKS_New_Conversation_Note';
import BACK_LABEL from '@salesforce/label/c.fbc_Back';

const FLOW_API_NAME = 'Conversation_Note_Journal_From_Case';

export default class NksConversationNoteButtonContainer extends LightningElement {
    @api recordId;
    @api conversationNoteButtonLabel;
    @api journalAndShare = false;
    @api showBackButton = false;

    _journalConversation;
    labels = {
        newConversationNote: CONVERSATION_NOTE_NEW_LABEL,
        back: BACK_LABEL
    };

    @api
    get journalConversation() {
        return this._journalConversation;
    }

    set journalConversation(value) {
        this._journalConversation = value;
    }

    get conversationNoteButtonVariant() {
        return this.conversationNoteButtonLabel === this.labels.newConversationNote ? 'brand-outline' : 'brand';
    }

    handleFlowButtonClicked(event) {
        if (this.journalAndShare && event.detail === FLOW_API_NAME) {
            this._journalConversation = true;
        }
    }
}
