import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import LIVE_CHAT_TRANSCRIPT_THEME_GROUP from '@salesforce/schema/LiveChatTranscript.NKS_Theme_Group__c';
import CASE_THEME_GROUP from '@salesforce/schema/Case.NKS_Theme_Group__c';
export default class NksStripedListEntry extends NavigationMixin(LightningElement) {
    @api record;
    @api index;

    recordUrl;
    themeGroupId;
    chatThemeGroup = LIVE_CHAT_TRANSCRIPT_THEME_GROUP;
    caseThemeGroup = CASE_THEME_GROUP;
    _themeGroup;

    get themeGroup() {
        if (this._themeGroup == '' || this._themeGroup == null) {
            console.log('Theme group is null!');
            return '';
        } else {
            return this._themeGroup;
        }
    }

    get fieldName() {
        if (this.record.objectName == 'LiveChatTranscript') {
            return this.chatThemeGroup;
        } else if (this.record.objectName == 'Case') {
            return this.caseThemeGroup;
        } else {
            console.log('There is a problem to get field name');
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
    }

    getThemeGroupId() {
        getRelatedRecord({
            parentId: this.record.recordId,
            relationshipField: 'NKS_Theme_Group__c',
            objectApiName: this.record.objectName
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
        recordId: this.record.recordId,
        fields: this.record.objectName.Id
    })
    wiredRecord({ error, data }) {
        if (error) {
            console.log(error);
        } else if (data) {
            this.getThemeGroupId();
        }
    }

    @wire(getRecord, {
        recordId: this.themeGroupId,
        fields: [this.fieldName]
    })
    wiredThemeGroup({ error, data }) {
        if (error) {
            console.log(error);
        } else if (data) {
            this._themeGroup = getFieldValue(data, this.fieldName);
            console.log(this._themeGroup);
        }
    }

    resolve(path, obj) {
        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || self);
    }
}
