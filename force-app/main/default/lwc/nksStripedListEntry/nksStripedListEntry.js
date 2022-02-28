import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import THEME_ID from '@salesforce/schema/Common_Code__c.Id';
import THEME_GROUP from '@salesforce/schema/Common_Code__c.Name';

export default class NksStripedListEntry extends NavigationMixin(LightningElement) {
    @api record;
    @api index;
    @api lastIndex;

    recordUrl;

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
        //this.themeGroupId = this.record.name;
    }

    get className() {
        let cssClass = 'slds-grid slds-var-p-horizontal_medium slds-var-p-vertical_x-small listItem';
        if (this.index % 2 == 0) {
            cssClass += ' isEven';
        }
        if (this.index == 0) {
            cssClass += ' isFirst';
        }
        if (this.index == this.lastIndex) {
            cssClass += ' isLast';
        }
        return cssClass;
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

    /*
    themeGroupId;
    _themeGroup;

    get themeGroup() {
        if (this._themeGroup === '' || this._themeGroup == null) {
            console.log('Theme group is not defined for this record.');
            return '';
        } else {
            return this._themeGroup;
        }
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
    */
}
