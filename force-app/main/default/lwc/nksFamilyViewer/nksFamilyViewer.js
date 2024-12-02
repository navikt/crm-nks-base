import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getRelations from '@salesforce/apex/NKS_FamilyViewController.getRelations';
import nksFamilyViewerV2HTML from './nksFamilyViewerV2.html';
import nksFamilyViewerHTML from './nksFamilyViewer.html';

export default class nksFamilyViewer extends LightningElement {
    @api objectApiName;
    @api recordId;
    @api useNewDesign;
    wireFields;
    isLoaded = false;

    render() {
        return this.useNewDesign ? nksFamilyViewerV2HTML : nksFamilyViewerHTML;
    }

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ data }) {
        if (data) {
            refreshApex(this.relations).then(() => {
                this.isLoaded = true;
            });
        }
    }

    @wire(getRelations, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    relations;

    get divider() {
        return this.useNewDesign ? '' : 'slds-has-dividers_top-space';
    }
}
