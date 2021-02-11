import { LightningElement, api, wire } from 'lwc';
import getRelatedPersons from '@salesforce/apex/FamilyRelationViewerController.getRelatedPersons';

export default class PersonRelationViewer extends LightningElement {
    @api objectApiName;
    @api recordId;

    @wire(getRelatedPersons, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    relations;
}
