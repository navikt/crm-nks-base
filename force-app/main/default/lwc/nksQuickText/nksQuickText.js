import { LightningElement, track, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import searchRecords from "@salesforce/apex/NKS_QuickTextSearchController.searchRecords";
import getRecentlyViewedRecords from "@salesforce/apex/NKS_QuickTextSearchController.getRecentlyViewedRecords";

export default class nksQuickText extends LightningElement {

    @api comments;
    @track data;
    myVal;
    @track comments = '';
    @track allrecords;

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
        getRecentlyViewedRecords()
            .then(result => {
                this.data = result;
            })
            .catch(error => {
                //TODO: error message
            })
        this.template.querySelector('[data-id="modal"]').className = 'modalShow';
        this.template.querySelector('lightning-input').focus();
    }


    hideModal(event) {
        this.template.querySelector('[data-id="modal"]').className = 'modalHide';
    }

    insertText(event) {
        this.myVal = this.comments + event.currentTarget.dataset.message;
        this.template.querySelector('[data-id="modal"]').className = 'modalHide';
        this.template.querySelector('textarea ').value = this.myVal;
        const attributeChangeEvent = new FlowAttributeChangeEvent('comments', this.myVal);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleChange(event) {
        this[event.target.name] = event.target.value;
        const attributeChangeEvent = new FlowAttributeChangeEvent('comments', this.template.querySelector('textarea').value);
        this.dispatchEvent(attributeChangeEvent);
    }
}