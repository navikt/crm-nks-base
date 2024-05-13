import { LightningElement, api } from 'lwc';
import CONVERSATION_NOTE_NEW_LABEL from '@salesforce/label/c.NKS_New_Conversation_Note';

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

    get isJournalAndShare() {
        return (
            this.journalConversation &&
            !this.template.querySelector('c-nks-button-container-bottom').showCreateNavTaskFlow
        );
    }

    handleJournalButtonClicked() {
        if (this.journalAndShare) {
            this._journalConversation = true;
        }
    }
}
