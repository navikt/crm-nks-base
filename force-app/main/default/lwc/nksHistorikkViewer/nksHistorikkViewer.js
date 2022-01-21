import { LightningElement, api } from 'lwc';
export default class NksHistorikkViewer extends LightningElement {
    @api objectApiName;
    @api recordId;
    @api fullmaktData;
}
