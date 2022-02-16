import { LightningElement, track } from 'lwc';
import getReadyResponse from '@salesforce/apex/NKS_HomePageController.getReadyResponse';
import { NavigationMixin } from 'lightning/navigation';

export default class NksLinksReadyResponse extends NavigationMixin(LightningElement) {
    @track records = [];
    size;
    className;

    isInitiated = false;

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
            this.size = 8;
            this.className = 'slds-var-p-left_large';
            return true;
        } else {
            this.size = 12;
            this.className = '';
            return false;
        }
    }
}
