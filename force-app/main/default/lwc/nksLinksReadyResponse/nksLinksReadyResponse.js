import { LightningElement, track } from 'lwc';
import getReadyResponse from '@salesforce/apex/NKS_HomePageController.getReadyResponses';
export default class nksLinksReadyResponse extends LightningElement {
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
        let show;
        if (this.records.length > 0) {
            this.size = 7;
            this.className = 'slds-var-p-left_large';
            show = true;
        } else {
            this.size = 12;
            this.className = '';
            show = false;
        }
        return show;
    }
}
