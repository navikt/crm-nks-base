import { LightningElement, track, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import NAV_TASK_OBJECT from '@salesforce/schema/NAVTask__c';


import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import SUB_THEME_FIELD from '@salesforce/schema/NavTask__c.NKS_Undertheme__c';
import THEME_FIELD from '@salesforce/schema/NavTask__c.NKS_Theme__c';

export default class NksThemesPicklists extends LightningElement {

    @api selectedTheme;
    @api selectedSubTheme;
    @track themes;
    @track subthemes;
    @wire(getObjectInfo, { objectApiName: NAV_TASK_OBJECT })
    navTaskInfo;

    @wire(getPicklistValues, { recordTypeId: '$navTaskInfo.data.defaultRecordTypeId', fieldApiName: SUB_THEME_FIELD })
    subThemeFieldInfo({ data, error }) {
        if (data) this.subFieldData = data;
    }

    @wire(getPicklistValues, { recordTypeId: '$navTaskInfo.data.defaultRecordTypeId', fieldApiName: THEME_FIELD })
    themeFieldInfo({ data, error }) {
        if (data) this.themes = data.values;
    }

    handleThemeChange(event) {
        let key = this.subFieldData.controllerValues[event.target.value];
        this.subthemes = this.subFieldData.values.filter(opt => opt.validFor.includes(key));
        this.selectedTheme = event.detail.value;
    }

    handleSubThemeChange(event) {
        this.selectedSubTheme = event.detail.value;
    }
}