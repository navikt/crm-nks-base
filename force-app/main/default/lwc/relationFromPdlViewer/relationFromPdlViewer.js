import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getRelatedPersons from '@salesforce/apex/FamilyRelationPDLViewerController.getRelatedPersons';

export default class RelationFromPdlViewer extends LightningElement {
    @api objectApiName;
    @api recordId;
    wireFields;
    isLoaded = false;

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ data }) {
        if (data) {
            refreshApex(this.relations).then(() => this.isLoaded = true);
        }
    }

    @wire(getRelatedPersons, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    relations;
}
