import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import THEME_GROUP from '@salesforce/schema/Common_Code__c.Name';
export default class NksStripedListEntry extends NavigationMixin(LightningElement) {
    @api record;
    @api index;

    recordUrl;
    themeGroupId;
    _themeGroup;
    recordId;
    objectApiName;
    wireField;
    themeGroupField;

    get themeGroup() {
        if (this._themeGroup == '' || this._themeGroup == null) {
            console.log('Theme group is null!');
            return '';
        } else {
            return this._themeGroup;
        }
    }

    get className() {
        return this.index % 2 == 0
            ? 'slds-grid slds-var-p-horizontal_medium slds-var-p-vertical_x-small listItem isEven'
            : 'slds-grid slds-var-p-horizontal_medium slds-var-p-vertical_x-small listItem';
    }

    navigateToPage(event) {
        event.preventDefault();
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

    connectedCallback() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        }).then((url) => {
            this.recordUrl = url;
        });
        this.recordId = this.record.recordId;
        this.objectApiName = this.record.objectName;
        this.wireField = [this.objectApiName + '.Id'];
        this.themeGroupField = ['Common_Code__c.Id'];
    }

    getThemeGroupId() {
        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: 'NKS_Theme_Group__c',
            objectApiName: this.objectApiName
        })
            .then((record) => {
                this.themeGroupId = this.resolve('NKS_Theme_Group__c', record);
                console.log(this.themeGroupId);
            })
            .catch((error) => {
                console.log(error);
            });
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireField'
    })
    wiredRecord({ error, data }) {
        if (error) {
            console.log(error);
        } else if (data) {
            this.getThemeGroupId();
        }
    }

    @wire(getRecord, {
        recordId: '$themeGroupId',
        fields: '$themeGroupField'
    })
    wiredThemeGroup({ error, data }) {
        if (error) {
            console.log(error);
        } else if (data) {
            this._themeGroup = getFieldValue(data, THEME_GROUP);
        }
    }

    resolve(path, obj) {
        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || self);
    }
}
