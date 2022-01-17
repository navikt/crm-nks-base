import { LightningElement, track, api, wire } from 'lwc';
import searchRecords from '@salesforce/apex/NKS_QuickTextSearchController.searchRecords';
import getQuicktexts from '@salesforce/apex/NKS_QuickTextSearchController.getQuicktexts';
//LABEL IMPORTS
import BLANK_ERROR from '@salesforce/label/c.NKS_Conversation_Note_Blank_Error';
export default class nksQuickText extends LightningElement {
    @api comments;
    @api required = false;

    @track data = [];

    labels = {BLANK_ERROR};
    _conversationNote;
    loadingData = false;
    quicktexts;
    qmap;
    initialRender = true;
    bufferFocus = false;
    numberOfRows = 0; 

    renderedCallback () {
        if (this.initialRender === true) {
            let inputField = this.template.querySelector('.conversationNoteTextArea');
            inputField.focus();
            inputField.blur();
            this.initialRender = false;
        }
        
        if (this.bufferFocus) {
            this.focusModal();
        }
    }

    disconnectedCallback() {
        document.removeEventListener('focusin', this.handleModalFocus, true);
    }

    modalOnEscape (evt) {
        if (evt.key === 'Escape') {
            this.hideModal(evt);
            evt.preventDefault();
            evt.stopImmediatePropagation();
        }
    }

    @api 
    showModal (event) {
        let modal = this.template.querySelector('[data-id="modal"]');
        modal.className = 'modalShow';
        this.template.querySelector('lightning-input').focus();
        document.addEventListener('focusin', this.handleModalFocus, true);
        this.focusModal();
    }

    hideModal (event) {
        let modal = this.template.querySelector('[data-id="modal"]');
        modal.className = 'modalHide';
        document.removeEventListener('focusin', this.handleModalFocus, true);
    }

    focusModal() {
        const modal = this.template.querySelector('[data-id="modal"]');
        if (modal) {
            this.bufferFocus = false;
            modal.focus();
        } else {
            this.bufferFocus = true;
        }
    }

    @api 
    isOpen () {
        if (this.template.querySelector('[data-id="modal"]').className == 'modalShow') {
            return true;
        } else {
            return false;
        }
    }

    handleModalFocus = (event) => {
        if (this.isOpen()) {
            let modal = false;
            event.path.forEach((pathItem) => {
                if (pathItem.ariaModal) {
                    modal = true;
                    return;
                }
            }); 
            
            if (!modal) {
                const modalFocusElement = this.template.querySelector('.slds-modal__close');
                modalFocusElement.focus();
            }  
        }
    }

    handleKeyUp(evt) {
        const queryTerm = evt.target.value;

        if (evt.key.length > 1 && evt.key !== 'Enter') {
            return;
        }

        if (evt.key === 'Enter' || (queryTerm.length > 2 && this.loadingData == false)) {
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

    @wire (getQuicktexts, {})
    wiredQuicktexts (value) {
        if (value.data) {
            this.quicktexts = value.data;
            this.qmap = new Map(value.data.map((key) => [key.nksAbbreviationKey__c.toUpperCase(), key.Message]));
        }
    }

    get inputFormats () {
        return [''];
    }

    @api 
    get conversationNote () {
        return this._conversationNote;
    }

    set conversationNote (value) {
        this._conversationNote = value;
    }

    @api 
    get conversationNoteRich () {
        return this._conversationNote;
    }

    set conversationNoteRich (value) {
        this._conversationNote = value;
    }

    handlePaste(evt) {
        const editor = this.template.querySelector('.conversationNoteTextArea');
        editor.setRangeText(
            this.toPlainText((evt.clipboardData || window.clipboardData).getData('text')),
            editor.selectionStart,
            editor.selectionEnd,
            'end'
        );
        evt.preventDefault();
        evt.stopImmediatePropagation();

        this.conversationNote = editor.value;
        const attributeChangeEvent = new CustomEvent('commentschange', {
            detail: this.conversationNote
        });
        this.dispatchEvent(attributeChangeEvent);
    }

    insertText (event) {
        const editor = this.template.querySelector('.conversationNoteTextArea');
        editor.focus();
        editor.setRangeText(
            this.toPlainText(event.currentTarget.dataset.message),
            editor.selectionStart,
            editor.selectionEnd,
            'select'
        );

        this.hideModal (undefined);
        this.conversationNote = editor.value;
        const attributeChangeEvent = new CustomEvent('commentschange', {
            detail: this.conversationNote
        });
        this.dispatchEvent(attributeChangeEvent);
    }

    handleChange (event) {
        this[event.target.name] = event.target.value;
        this.conversationNote = event.target.value;
        const attributeChangeEvent = new CustomEvent('commentschange', {
            detail: this.conversationNote
        });
        this.dispatchEvent(attributeChangeEvent);
    }

    insertquicktext (event) {
        if (event.keyCode === 32) {
            const editor = this.template.querySelector('.conversationNoteTextArea');
            const carretPositionEnd = editor.selectionEnd;
            const lastItem = editor.value
                .substring(0, carretPositionEnd)
                .replace(/(\r\n|\n|\r)/g, ' ')
                .trim()
                .split(' ')
                .pop();
            const abbreviation = lastItem.toUpperCase();
            const quickText = this.qmap.get(abbreviation);

            if (this.qmap.has(abbreviation)) {
                const startindex = carretPositionEnd - lastItem.length - 1;

                if (lastItem.charAt(0) === lastItem.charAt(0).toLowerCase()) {
                    const lowerCaseQuickText = quickText.toLowerCase();
                    editor.setRangeText(lowerCaseQuickText + ' ', startindex, carretPositionEnd, 'end');
                } else {
                    const upperCaseQuickText = quickText.charAt(0).toUpperCase() + quickText.slice(1);
                    editor.setRangeText(upperCaseQuickText + ' ', startindex, carretPositionEnd, 'end');
                }
            }
        }
    }

    toPlainText (value) {
        let plainText = value ? value : '';
        plainText = plainText.replace(/<\/[^\s>]+>/g, '\n'); //Replaces all ending tags with newlines.
        plainText = plainText.replace(/<[^>]+>/g, ''); //Remove remaining html tags
        plainText = plainText.replace(/&nbsp;/g, ' '); //Removes &nbsp; from the html that can arise from copy-paste
        return plainText;
    }

    setFocusOnTextArea () {
        let inputField = this.template.querySelector('.conversationNoteTextArea');
        inputField.focus();
    }

    @api
    validate () {
        if (this.required === true) {
            return this.conversationNote && this.conversationNote.length > 0
                ? { isValid: true }
                : { isValid: false, errorMessage: this.labels.BLANK_ERROR }; //CUSTOM LABEL HERE
        } else {
            return { isValid: true };
        }
    }
}