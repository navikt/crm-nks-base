import { LightningElement, track, api } from 'lwc';
import searchRecords from '@salesforce/apex/NKS_QuickTextSearchController.searchRecords';

//LABEL IMPORTS
import BLANK_ERROR from '@salesforce/label/c.NKS_Conversation_Note_Blank_Error';
export default class nksQuickText extends LightningElement {
    labels = {
        BLANK_ERROR
    };

    @api comments;
    @api conversationNote;
    @track data;
    loadingData = false;
    @api required = false;

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
        this.conversationNote = this.conversationNote + event.currentTarget.dataset.message;
        this.template.querySelector('[data-id="modal"]').className = 'modalHide';
        this.template.querySelector('textarea').value = this.conversationNote;
        const attributeChangeEvent = new CustomEvent('commentschange', {
            detail: this.template.querySelector('textarea').value
        });
        this.dispatchEvent(attributeChangeEvent);
    }

    handleChange(event) {
        this[event.target.name] = event.target.value;
        this.conversationNote = event.target.value;
        const attributeChangeEvent = new CustomEvent('commentschange', {
            detail: this.template.querySelector('textarea').value
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
