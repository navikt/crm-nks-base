import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

export default class NksRecordInfo extends NavigationMixin(LightningElement) {
    @api recordId; // Id from record page (From UiRecordAPI)
    @api viewedRecordId; // Id of the record to display information for
    @api viewedObjectApiName = null; // API name of the object to display information from
    @api relationshipField = null; // Field api name if the recordId is to be set via relationship
    @api objectApiName; // Value from UiRecordAPI
    @api displayedFields = null;
    @api cardLabel;
    @api iconName; // Name of the icon to display on the format required from the icon-name attribute in lighning:card
    @api numCols = 2; // Number of columns for the displayed fields
    @api hideLabels = false; // Boolean to determine if labels is to be displayed
    _showLink = false; // Boolean to determine if action slot is to be displayed
    @api wireFields;

    connectedCallback() {
        this.viewedObjectApiName =
            this.viewedObjectApiName == null ? this.objectApiName : this.viewedObjectApiName;
        if (this.relationshipField != null && this.relationshipField != '') {
            this.getRelatedRecordId(this.relationshipField, this.objectApiName);
        }
        this.viewedRecordId = this.viewedRecordId ? this.viewedRecordId : this.recordId;

        this.wireFields = [this.viewedObjectApiName + '.Id'];
    }

    @api
    set showLink(value) {
        this._showLink = value === 'TRUE' || value === 'true' || value === true ? true : false;
    }

    get showLink() {
        return this._showLink;
    }

    getRelatedRecordId(relationshipField, objectApiName) {
        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: relationshipField,
            objectApiName: objectApiName
        })
            .then((record) => {
                this.viewedRecordId = this.resolve(relationshipField, record);
            })
            .catch((error) => {
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
        let fieldList =
            this.displayedFields != null ? this.displayedFields.replace(/\s/g, '').split(',') : [];
        return fieldList;
    }

    //Opens the account page on click
    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.viewedRecordId,
                objectApiName: this.viewedObjectApiName,
                actionName: 'view'
            }
        });
    }

    @wire(getRecord, {
        recordId: '$viewedRecordId',
        fields: '$wireFields'
    })
    wireRecord;

    //Supports refreshing the record
    @api
    refreshRecord() {
        refreshApex(this.wireRecord);
    }

    recordLoaded(event) {
        let recordFields = event.detail.records[this.viewedRecordId].fields;
        //Sending event to tell parent the record is loaded
        const recordLoadedEvt = new CustomEvent('recordloaded', {
            detail: recordFields
        });
        this.dispatchEvent(recordLoadedEvt);
    }

    /*
     * HELPER FUNCTIONS
     */

    /**
     * Retrieves the value from the given object's data path
     * @param {data path} path
     * @param {JS object} obj
     */
    resolve(path, obj) {
        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || self);
    }
}
