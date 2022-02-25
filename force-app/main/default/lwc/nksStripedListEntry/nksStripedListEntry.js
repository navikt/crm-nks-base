import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import THEME_ID from '@salesforce/schema/Common_Code__c.Id';
import THEME_GROUP from '@salesforce/schema/Common_Code__c.Name';
export default class NksStripedListEntry extends NavigationMixin(LightningElement) {
    @api record;
    @api index;

    recordUrl;
    themeGroupId;
    _themeGroup;

    get className() {
        return this.index % 2 == 0
            ? 'slds-grid slds-var-p-horizontal_medium slds-var-p-vertical_x-small listItem isEven'
            : 'slds-grid slds-var-p-horizontal_medium slds-var-p-vertical_x-small listItem';
    }

    get themeGroup() {
        if (this._themeGroup === '' || this._themeGroup == null) {
            console.log('Theme group is not defined for this record.');
            return '';
        } else {
            return this._themeGroup;
        }
    }

    navigateToPage(event) {
        event.preventDefault();
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.recordId,
                actionName: 'view'
            }
        });
    }

    connectedCallback() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.recordId,
                actionName: 'view'
            }
        }).then((url) => {
            this.recordUrl = url;
        });
        this.themeGroupId = this.record.name;
    }

    @wire(getRecord, {
        recordId: '$themeGroupId',
        fields: [THEME_ID, THEME_GROUP]
    })
    wiredThemeGroup({ error, data }) {
        if (error) {
            console.log(error);
        } else if (data) {
            if (this.themeGroupId) {
                this._themeGroup = getFieldValue(data, THEME_GROUP);
            }
        }
    }

    resolve(path, obj) {
        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || self);
    }
}
