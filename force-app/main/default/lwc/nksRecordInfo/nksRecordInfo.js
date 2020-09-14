import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';

export default class NksRecordInfo extends NavigationMixin(LightningElement) {
    @api recordId;                  // Id from record page (From UiRecordAPI)
    @api viewedRecordId;            // Id of the record to display information for
    @api viewedObjectApiName = null // API name of the object to display information from
    @api relationshipField = null;  // Field api name if the recordId is to be set via relationship
    @api objectApiName;             // Value from UiRecordAPI
    @api displayedFields = null;
    @api cardLabel;
    @api iconName;                  // Name of the icon to display on the format required from the icon-name attribute in lighning:card
    @api numCols = 2;               // Number of columns for the displayed fields

    connectedCallback() {
        this.viewedObjectApiName = this.viewedObjectApiName == null ? this.objectApiName : this.viewedObjectApiName;
        if (this.relationshipField != null) {
            this.getRelatedRecordId(this.relationshipField, this.objectApiName);
        }
    }

    getRelatedRecordId(relationshipField, objectApiName) {
        getRelatedRecord({ parentId: this.recordId, relationshipField: relationshipField, objectApiName: objectApiName })
            .then(record => {
                this.viewedRecordId = record[relationshipField];
            })
            .catch(error => {
                console.log(error);
            });
    }

    get columnWidth() {
        return 12 / this.numCols;
    }

    get recordIdSet() {
        return this.viewedRecordId != null;
    }

    get fieldList() {
        let fieldList = this.displayedFields != null ? this.displayedFields.replace(/\s/g, "").split(",") : [];
        return fieldList;
    }

    //Opens the account page on click
    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.viewedRecordId,
                objectApiName: this.objectApiName,
                actionName: 'view'
            }
        });
    }
}