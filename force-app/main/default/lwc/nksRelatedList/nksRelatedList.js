import { LightningElement, api, track, wire } from 'lwc';
import getRelatedList from '@salesforce/apex/NKS_RelatedListController.getRelatedList';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

export default class NksRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api relatedRecords;

    //## DESIGN INPUTS ##
    @api listTitle; //Title of the list.
    @api iconName; //Displayed icon.
    @api columnLabels; //Columns to be displayed.
    @api relatedObjectApiName; //Object name of the records in the list
    @api relationField; //Field API name of the lookup/master-detail connecting the parent
    @api parentRelationField; //Field API name of hos the parent is related in the junction
    @api filterConditions; //Optional filter conditions (i.e. Name != 'TEST')
    @api headerColor; // Color for the component header
    @api dynamicUpdate = false; // Flag to set if component should automatically refresh if the an update is triggered on the parent record page
    @api wireFields;
    @api maxHeight = 20; //Defines the max height in em of the component
    @api clickableRows; //Enables row click to fire navigation event to the clicked record in the table
    @api hideEmptyList; // Hides the list if there are no related records.

    @api displayedFields;

    connectedCallback() {
        //Call apex to retrieve related records
        this.wireFields = [this.objectApiName + '.Id'];
        this.getList();
    }

    //Wire function to allow for dynamic update
    @wire(getRecord, { recordId: '$recordId', fields: '$wireFields' })
    getaccountRecord({ data, error }) {
        if (data) {
            if (this.dynamicUpdate === true) {
                this.getList();
            }
        } else if (error) {
            //Error
        }
    }

    //Calls apex to retrieve related records
    getList() {
        getRelatedList({
            parentId: this.recordId,
            objectApiName: this.relatedObjectApiName,
            relationField: this.relationField,
            parentRelationField: this.parentRelationField,
            parentObjectApiName: this.objectApiName,
            filterConditions: this.filterConditions
        })
            .then((data) => {
                this.relatedRecords = data && data.length > 0 ? data : null;
            })
            .catch((error) => {
                console.log('An error occurred: ' + JSON.stringify(error, null, 2));
            });
    }

    handleRowClick(event) {
        let recordIndex = event.currentTarget.dataset.value;
        this.navigateToRecord(this.relatedRecords[recordIndex].Id);
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: this.relatedObjectApiName,
                actionName: 'view'
            }
        });
    }

    get cardTitle() {
        return this.listTitle + ' (' + this.numRecords + ')';
    }

    get numRecords() {
        return this.relatedRecords ? this.relatedRecords.length : 0;
    }

    get headerBackground() {
        return this.headerColor
            ? 'background-color: ' + this.headerColor + '; border-color: ' + this.headerColor + 'border-style: solid'
            : '';
    }

    get scrollableStyle() {
        return this.maxHeight != 0 ? 'max-height: ' + this.maxHeight.toString() + 'em' : '';
    }

    get usedFields() {
        return this.displayedFields != null ? this.displayedFields.replace(/\s/g, '').split(',') : [];
    }

    get icon() {
        let nameString = null;
        if (this.iconName && this.iconName != '') nameString = this.iconName;

        return nameString;
    }

    get showCard() {
        return !this.hideEmptyList || (this.relatedRecords != null && this.relatedRecords.length > 0);
    }
}
