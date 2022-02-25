import { LightningElement, api, track } from 'lwc';
import getReadyResponse from '@salesforce/apex/NKS_HomePageController.getReadyResponse';
export default class NksLinksReadyResponse extends LightningElement {
    @api showReadyResponse;
    @api urlInput; // this will be removed
    @api titleInput; // this will be removed

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
