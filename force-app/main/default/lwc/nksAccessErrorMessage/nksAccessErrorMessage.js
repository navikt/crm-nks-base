import { LightningElement, api, wire } from 'lwc';
import checkAccess from '@salesforce/apex/NKS_AccessErrorController.checkAccess';

export default class NksAccessErrorMessage extends LightningElement {
    @api objectApiName;
    @api recordId;

    @wire(checkAccess, { recordId: '$recordId', objectApiName: '$objectApiName' })
    access;
}