import {LightningElement, api, wire} from 'lwc';
import getRelatedPersons from '@salesforce/apex/FamilyRelationViewerController.getRelatedPersons';

export default class PersonRelationViewer extends LightningElement {
x
    @api personIdField;
    @api recordId;

    // Todo dynamically get Id from field referenced in personIdField
    @wire(getRelatedPersons, {personId: '$recordId' })
    relations;

}