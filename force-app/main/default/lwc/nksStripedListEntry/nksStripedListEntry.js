import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import THEME_ID from '@salesforce/schema/Common_Code__c.Id';
import THEME_GROUP from '@salesforce/schema/Common_Code__c.Name';
import userId from '@salesforce/user/Id';
import getQueue from '@salesforce/apex/NKS_HomePageController.getQueue';
export default class NksStripedListEntry extends NavigationMixin(LightningElement) {
    @api record;
    @api index;
    @api lastIndex;

    recordUrl;
    userId;
    theme;

    themeGroupId;
    _themeGroup;

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
        this.userId = userId;
        this.getTheme();
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

    getTheme() {
        if (this.record.objectApiName === 'LiveChatTranscript') {
            getQueue({ userId: this.userId })
                .then((result) => {
                    this.theme = result;
                })
                .catch((error) => {
                    this.error = error;
                });
        }
        if (this.record.objectApiName === 'Case') {
            this.theme = this.record.name;
        } else {
            console.log('Something went wrong while getting theme!');
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
}
