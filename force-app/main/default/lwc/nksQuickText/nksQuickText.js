import { LightningElement, track, api } from 'lwc';
import searchRecords from "@salesforce/apex/NKS_QuickTextSearchController.searchRecords";

export default class nksQuickText extends LightningElement {

    @api comments;
    @track isModal = false;
    @track data;

    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        const queryTerm = evt.target.value;

        console.log(queryTerm);
        if (isEnterKey) {
            searchRecords({
                search: queryTerm
            })
                .then(result => {
                    this.numberOfRows = result.length;
                    this.data = result;
                })
                .catch(error => {
                    //helper.senderror 
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
        console.log(event.currentTarget.dataset.message);
        //TODO: Insert message in text box 
    }

    get myVal() {
        return;
    }
}