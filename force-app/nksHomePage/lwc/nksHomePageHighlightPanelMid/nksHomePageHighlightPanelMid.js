import { LightningElement, wire } from 'lwc';
import getReadyResponse from '@salesforce/apex/NKS_HomePageController.getReadyResponses';

export default class NksPersonHighlightPanelMid extends LightningElement {
    records = [];

    @wire(getReadyResponse)
    wiredRecords({ error, data }) {
        if (data) {
            this.records = data;
        } else if (error) {
            console.error(`Feil ved henting av svarberedskaper: ${error}`);
        }
    }
}
