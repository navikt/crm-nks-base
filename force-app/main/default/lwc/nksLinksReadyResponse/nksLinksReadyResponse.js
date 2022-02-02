import { LightningElement, api, track } from 'lwc';
import getReadyResponse from '@salesforce/apex/NKS_HomePageController.getReadyResponse';
import { NavigationMixin } from 'lightning/navigation';

export default class nksLinksReadyResponse extends NavigationMixin(LightningElement) {
    @api showReadyResponse;
    @track records;

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
}
