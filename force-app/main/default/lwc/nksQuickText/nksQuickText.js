import { LightningElement, track, api, wire } from 'lwc';
import searchRecords from '@salesforce/apex/NKS_QuickTextSearchController.searchRecords';
import getQuicktexts from '@salesforce/apex/NKS_QuickTextSearchController.getQuicktexts';
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
    quicktexts;
    qmap;
    get inputFormats() {
        return [''];
    }
    initialRender = true;

    //Screen reader does not detect component as as input field until after the first focus
    renderedCallback() {
        if (this.initialRender === true) {
            let inputField = this.template.querySelector('lightning-input-rich-text');
            inputField.focus();
            inputField.blur();
            this.initialRender = false;
        }
    }

    @wire(getQuicktexts, {})
    wiredQuicktexts(value) {
        if (value.data) {
            this.quicktexts = value.data;
            this.qmap = new Map(value.data.map((key) => [key.nksAbbreviationKey__c.toUpperCase(), key.Message]));
        }
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

    insertquicktext(event) {
        const isSpaceKey = event.keyCode === 32;
        if (isSpaceKey) {
            var textval = this.conversationNote.replace(/(\r\n|\n|\r)/gm, '');
            var stringarray = textval.trim().split(' ');
            const lastItem = stringarray[stringarray.length - 1].toUpperCase();
            if (this.qmap.has(lastItem)) {
                const inserttext = this.qmap.get(lastItem);
                const editor = this.template.querySelector('lightning-input-rich-text');
                const startindex = this.conversationNote.length - lastItem.length - 2;
                editor.setRangeText(inserttext + ' ', startindex, startindex + inserttext.length, 'end');
            }
        }
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
