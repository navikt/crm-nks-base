import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getRelatedPersons from '@salesforce/apex/FamilyRelationViewerController.getRelatedPersons';

export default class PersonRelationViewer extends LightningElement {
    @api objectApiName;
    @api recordId;
    wireFields;

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ data }) {
        if (data) {
            refreshApex(this.relations);
            console.log('DONEEEE');
        }
    }

    @wire(getRelatedPersons, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    relations;
}
