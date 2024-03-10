import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import CREATE_CONVERSATION_NOTE_HEADER from '@salesforce/label/c.NKS_Create_Conversation_Note';
import CONVERSATION_NOTE_DISCLAIMER_TEXT from '@salesforce/label/c.NKS_Conversation_Note_Disclaimer_Text';

export default class NksConversationNoteContainer extends LightningElement {
    @api recordId;
    @api conversationNoteButtonLabel;
    @api journalButtonLabel;
    @api journalFlowName;

    _conversationNote;
    _themeGroup;
    _theme;
    header = CREATE_CONVERSATION_NOTE_HEADER;
    disclaimerText = CONVERSATION_NOTE_DISCLAIMER_TEXT;

    @api
    get themeGroup() {
        return this._themeGroup;
    }

    set themeGroup(value) {
        this._themeGroup = value;
    }

    @api
    get theme() {
        return this._theme;
    }

    set theme(value) {
        this._theme = value;
    }

    @api
    get conversationNote() {
        return this._conversationNote;
    }

    set conversationNote(value) {
        this._conversationNote = value;
    }

    handleConversationNoteChange(event) {
        this._conversationNote = event.detail;
        this.dispatchEvent(new FlowAttributeChangeEvent('dialogueSummaryInput', this.conversationNote));
    }

    handleThemeCategorizationChange(event) {
        this._themeGroup = event.target.themeGroup;
        this._theme = event.target.theme;

        this.dispatchEvent(new FlowAttributeChangeEvent('themeGroup', this.themeGroup));
        if (this.theme != null) {
            this.dispatchEvent(new FlowAttributeChangeEvent('theme', this.theme));
        }
    }
}
