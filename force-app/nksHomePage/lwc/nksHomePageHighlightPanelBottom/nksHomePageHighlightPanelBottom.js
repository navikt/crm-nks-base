import { LightningElement, wire } from 'lwc';
import getReadyResponse from '@salesforce/apex/NKS_HomePageController.getReadyResponses';

export default class NksHomePageHighlightPanelBottom extends LightningElement {
    records = [];

    @wire(getReadyResponse)
    wiredRecords({ error, data }) {
        if (data) {
            this.records = data.length > 0 ? data : [];
            console.log('Data fetched successfully:', this.records);
        } else if (error) {
            this.records = [];
            console.error(`There was an error fetching data: ${error.body.message}`);
        }
    }

    get hasRecords() {
        return this.records && this.records.length > 0;
    }
}
