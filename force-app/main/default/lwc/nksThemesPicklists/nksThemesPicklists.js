import { LightningElement, track, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import NAV_TASK_OBJECT from '@salesforce/schema/NavTask__c';


import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import SUB_THEME_FIELD from '@salesforce/schema/NavTask__c.CRM_SubTheme__c';
import THEME_FIELD from '@salesforce/schema/NavTask__c.CRM_Theme__c';

export default class NksThemesPicklists extends LightningElement {

    @api selectedTheme;
    @api selectedSubTheme;
    @api theme;
    @api subTheme;
    @track theme = this.theme;
    @track themes;
    @track subTheme = this.subTheme;
    @track subthemes;
    @wire(getObjectInfo, { objectApiName: NAV_TASK_OBJECT })
    navTaskInfo;

    @wire(getPicklistValues, { recordTypeId: '$navTaskInfo.data.defaultRecordTypeId', fieldApiName: THEME_FIELD })
    themeFieldInfo({ data, error }) {
        if (data) this.themes = data.values;
    }

    @wire(getPicklistValues, { recordTypeId: '$navTaskInfo.data.defaultRecordTypeId', fieldApiName: SUB_THEME_FIELD })
    subThemeFieldInfo({ data, error }) {
        if (data && this.themes) {
            this.subFieldData = data;
            //get array key for selected theme
            var selectedThemeKey = 0;
            for (var i = 0; i < this.themes.length; i++) {
                if (this.themes[i].value == this.theme) {
                    selectedThemeKey = i;
                }
            }
            this.subthemes = this.subFieldData.values.filter(opt => opt.validFor.includes(selectedThemeKey));
        }
    }

    handleThemeChange(event) {
        let key = this.subFieldData.controllerValues[event.target.value];
        this.subthemes = this.subFieldData.values.filter(opt => opt.validFor.includes(key));

        this.selectedTheme = event.detail.value;

        const selectedThemeEvent = new CustomEvent('themechange', {

            detail: this.selectedTheme
        });

        this.dispatchEvent(selectedThemeEvent);
    }

    handleSubThemeChange(event) {
        this.selectedSubTheme = event.detail.value;
        const selectedSubThemeEvent = new CustomEvent('subthemechange', {

            detail: this.selectedSubTheme
        });

        this.dispatchEvent(selectedSubThemeEvent);
    }


}