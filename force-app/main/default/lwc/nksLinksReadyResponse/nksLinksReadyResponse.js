import { LightningElement, api, track } from 'lwc';
import getReadyResponse from '@salesforce/apex/NKS_HomePageController.getReadyResponse';
export default class NksLinksReadyResponse extends LightningElement {
    @api showReadyResponse;
    @api urlInput; // this will be removed
    @api titleInput; // this will be removed

    @track records = [];

    isInitiated = false;
    size;
    className;

    connectedCallback() {
        this.isInitiated = true;
        this.loadList();
    }

    loadList() {
        getReadyResponse()
            .then((result) => {
                this.records = result;
            })
            .catch((error) => {
                console.log(error);
            });
    }

    get showReadyResponse() {
        if (this.records.length > 0) {
            this.size = 7;
            this.className = 'slds-var-p-left_large';
            return true;
        } else {
            this.size = 12;
            this.className = '';
            return false;
        }
    }
}
