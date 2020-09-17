import { LightningElement, track, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import searchRecords from "@salesforce/apex/NKS_QuickTextSearchController.searchRecords";

export default class nksQuickText extends LightningElement {

    @api comments;
    @track isModal = false;
    @track data;
    @track myVal;
    @track comments = '';

    get myVal() {
        return;
    }

    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        const queryTerm = evt.target.value;

        if (isEnterKey) {
            searchRecords({
                search: queryTerm
            })
                .then(result => {
                    this.numberOfRows = result.length;
                    this.data = result;
                })
                .catch(error => {
                    //TODO: senderror 
                })
        }
    }

    showModal(event) {
        this.isModal = true;
    }

    hideModal(event) {
        this.isModal = false;
    }

    insertText(event) {
        this.myVal = this.comments + event.currentTarget.dataset.message;
        this.isModal = false;
    }
    handleChange(event) {
        this[event.target.name] = event.target.value;
        const attributeChangeEvent = new FlowAttributeChangeEvent('comments', this.comments);
        this.dispatchEvent(attributeChangeEvent);
    }
}