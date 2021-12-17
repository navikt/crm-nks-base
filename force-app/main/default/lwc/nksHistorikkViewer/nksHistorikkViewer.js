import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getHistorikk from '@salesforce/apex/NKS_HistorikkViewController.getHistorikk';

export default class NksHistorikkViewer extends LightningElement {
    @api objectApiName;
    @api recordId;
    @api fullmaktData;
}
