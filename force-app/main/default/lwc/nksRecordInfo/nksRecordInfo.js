import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

import nksRefreshRecord from '@salesforce/messageChannel/nksRefreshRecord__c';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';

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
    @api parentWireFields;
    subscription;

    @wire(MessageContext)
    messageContext;

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    //Lightning message service subscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(this.messageContext, nksRefreshRecord, (message) => {
                let recordId = message.recordId;
                if (this.recordId == recordId) {
                    //If component is showing information in context of the updated record, update the related record id as it might have been changed
                    this.getRelatedRecordId(this.relationshipField, this.objectApiName);
                } else if (this.viewedRecordId == recordId) {
                    //If displaying information from the updated record -> refresh Apex
                    this.refreshRecord();
                }
            });
        }
    }

    //Lightning message service unsubsubscribe
    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    connectedCallback() {
        this.subscribeToMessageChannel();

        this.viewedObjectApiName = this.viewedObjectApiName == null ? this.objectApiName : this.viewedObjectApiName;
        if (this.relationshipField != null && this.relationshipField != '') {
            this.getRelatedRecordId(this.relationshipField, this.objectApiName);
        }
        this.viewedRecordId = this.viewedRecordId ? this.viewedRecordId : this.recordId;

        this.wireFields = [this.viewedObjectApiName + '.Id'];
        this.parentWireFields = [this.objectApiName + '.Id'];
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
        let fieldList = this.displayedFields != null ? this.displayedFields.replace(/\s/g, '').split(',') : [];
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

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$parentWireFields'
    })
    dewireParent(data, error) {
        //If the parent is updated, the relation might have changed and component is reinitialized
        if (this.relationshipField) {
            this.getRelatedRecordId(this.relationshipField, this.objectApiName);
        }
    }

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
