import { LightningElement, track, api } from 'lwc';
import searchRecords from '@salesforce/apex/NKS_QuickTextSearchController.searchRecords';

//LABEL IMPORTS
import BLANK_ERROR from '@salesforce/label/c.NKS_Conversation_Note_Blank_Error';
export default class nksQuickText extends LightningElement {
    labels = {
        BLANK_ERROR
    };

    @api conversationNote;
    @api conversationNoteRich;
    @api comments;
    @track data;
    loadingData = false;
    @api required = false;

    get inputFormats() {
        return [''];
    }

    get conversationNote() {
        let plainText = this.conversationNoteRich ? this.conversationNoteRich : '';
        plainText = plainText.replace(/<\/[^\s>]+>/g, '\n'); //Replaces all ending tags with newlines.
        plainText = plainText.replace(/<[^\s>]+>/g, ''); //Remove remaining html tags
        return plainText;
    }

    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        const queryTerm = evt.target.value;

        if (isEnterKey || (queryTerm.length > 2 && this.loadingData == false)) {
            this.loadingData = true;
            searchRecords({
                search: queryTerm
            })
                .then((result) => {
                    this.numberOfRows = result.length;
                    this.data = result;
                })
                .catch((error) => {
                    console.log(error);
                })
                .finally(() => {
                    this.loadingData = false;
                });
        }
    }

    showModal(event) {
        this.template.querySelector('[data-id="modal"]').className = 'modalShow';
        this.template.querySelector('lightning-input').focus();
    }

    hideModal(event) {
        this.template.querySelector('[data-id="modal"]').className = 'modalHide';
    }

    insertText(event) {
        const editor = this.template.querySelector('lightning-input-rich-text');
        editor.setRangeText(event.currentTarget.dataset.message, undefined, undefined, 'select');
        this.conversationNoteRich = editor.value;
        this.template.querySelector('[data-id="modal"]').className = 'modalHide';
        const attributeChangeEvent = new CustomEvent('commentschange', {
            detail: this.conversationNote
        });
        this.dispatchEvent(attributeChangeEvent);
    }

    handleChange(event) {
        this[event.target.name] = event.target.value;
        this.conversationNoteRich = event.target.value;
        const attributeChangeEvent = new CustomEvent('commentschange', {
            detail: this.conversationNote
        });
        this.dispatchEvent(attributeChangeEvent);
    }

    @api
    validate() {
        if (this.required === true) {
            return this.conversationNote && this.conversationNote.length > 0
                ? { isValid: true }
                : { isValid: false, errorMessage: this.labels.BLANK_ERROR }; //CUSTOM LABEL HERE
        } else {
            return { isValid: true };
        }
    }
}
