import { LightningElement, api, track, wire } from 'lwc';
import getRelatedList from '@salesforce/apex/NKS_RelatedListController.getRelatedList';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { resolve } from 'c/nksComponentsUtils';

export default class NksRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    //## DESIGN INPUTS ##
    @api listTitle; //Title of the list.
    @api iconName; //Displayed icon.
    @api columnLabels; //Columns to be displayed.
    @api displayedFields = null;
    @api relatedObjectApiName; //Object name of the records in the list
    @api relationField; //Field API name of the lookup/master-detail connecting the parent
    @api parentRelationField; //Field API name of hos the parent is related in the junction
    @api filterConditions; //Optional filter conditions (i.e. Name != 'TEST')
    @api headerColor; // Color for the component header
    @api dynamicUpdate = false; // Flag to set if component should automatically refresh if the an update is triggered on the parent record page
    @api maxHeight = 20; //Defines the max height in em of the component
    @api clickableRows; //Enables row click to fire navigation event to the clicked record in the table
    @api wireFields;

    @track relatedRecords;

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
            fieldNames: this.fieldList,
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

    //Tranforms the record array into an array that allows for resolving field dynamically as LWC currently does not support this
    get listRecords() {
        let returnRecords = [];
        if (this.relatedRecords) {
            this.relatedRecords.forEach((dataRecord) => {
                let recordFields = [];
                this.fieldList.forEach((key) => {
                    if (key !== 'Id') {
                        let recordField = {
                            label: key,
                            value: resolve(key, dataRecord)
                        };
                        recordFields.push(recordField);
                    }
                });
                returnRecords.push({ recordFields: recordFields });
            });
        }
        return returnRecords;
    }

    get cardTitle() {
        const numRecords = this.relatedRecords ? this.relatedRecords.length : 0;
        return this.listTitle + ' (' + numRecords + ')';
    }

    get headerBackground() {
        return this.headerColor
            ? 'background-color: ' + this.headerColor + '; border-color: ' + this.headerColor + 'border-style: solid'
            : '';
    }

    get tableHeaderStyle() {
        return 'width: 100%; max-height: ' + this.maxHeight.toString() + 'em';
    }

    get scrollableStyle() {
        return 'max-height: ' + this.maxHeight.toString() + 'em';
    }

    get fieldLabels() {
        let labels = this.columnLabels != null ? this.columnLabels.replace(/\s/g, '').split(',') : [];
        return labels;
    }

    get fieldList() {
        let fieldList = this.displayedFields != null ? this.displayedFields.replace(/\s/g, '').split(',') : [];
        return fieldList;
    }

    get icon() {
        let nameString = null;
        if (this.iconName && this.iconName !== '') nameString = this.iconName;

        return nameString;
    }
}
