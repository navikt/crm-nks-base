import { LightningElement, track, api } from 'lwc';
import searchRecords from '@salesforce/apex/NKS_QuickTextSearchController.searchRecords';

export default class nksQuickText extends LightningElement {
    @api comments;
    @api conversationNote;
    @track data;
    myVal;
    @track comments = '';
    @track loadingData = false;

    get myVal() {
        return;
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
                    this.loadingData = false;
                })
                .catch((error) => {
                    console.log(error);
                });
        }
    }

    showModal(event) {
        this.template.querySelector('[data-id="modal"]').className =
            'modalShow';
        this.template.querySelector('lightning-input').focus();
    }

    hideModal(event) {
        this.template.querySelector('[data-id="modal"]').className =
            'modalHide';
    }

    insertText(event) {
        this.myVal = this.comments + event.currentTarget.dataset.message;
        this.template.querySelector('[data-id="modal"]').className =
            'modalHide';
        this.template.querySelector('textarea ').value = this.myVal;
        const attributeChangeEvent = new CustomEvent('commentschange', {
            detail: this.template.querySelector('textarea').value
        });
        this.dispatchEvent(attributeChangeEvent);
    }

    handleChange(event) {
        this[event.target.name] = event.target.value;
        const attributeChangeEvent = new CustomEvent('commentschange', {
            detail: this.template.querySelector('textarea').value
        });
        this.dispatchEvent(attributeChangeEvent);
    }
}
