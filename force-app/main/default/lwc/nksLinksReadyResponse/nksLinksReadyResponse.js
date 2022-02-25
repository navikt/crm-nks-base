import { LightningElement, api, track } from 'lwc';
import getReadyResponse from '@salesforce/apex/NKS_HomePageController.getReadyResponse';
export default class NksLinksReadyResponse extends LightningElement {
    @api showReadyResponse;
    @track records = [];

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
    /*
    get showReadyResponse() {
        return this.records.length > 0 ? true : false;
    } */
}
