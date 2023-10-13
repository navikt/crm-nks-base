import { LightningElement, track, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import NAV_TASK_OBJECT from '@salesforce/schema/NavTask__c';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import SUB_THEME_FIELD from '@salesforce/schema/NavTask__c.CRM_SubTheme__c';
import THEME_FIELD from '@salesforce/schema/NavTask__c.CRM_Theme__c';

export default class NksThemesPicklists extends LightningElement {
    objectApiName;
    employerRecordTypeId;
    @wire(getObjectInfo, { objectApiName: NAV_TASK_OBJECT })
    getobjectInfo(result) {
        if (result.data) {
            const rtis = result.data.recordTypeInfos;
            this.employerRecordTypeId = Object.keys(rtis).find((rti) => rtis[rti].name === 'Employer');
        }
    }
    @api selectedTheme;
    @api selectedSubTheme;
    @api theme;
    @api subTheme;
    @track themes;
    @track subthemes;
    @track theme = this.theme;
    @track subTheme = this.subTheme;

    @wire(getPicklistValues, {
        recordTypeId: '$employerRecordTypeId',
        fieldApiName: THEME_FIELD
    })
    themeFieldInfo({ data, error }) {
        if (data) this.themes = data.values;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$employerRecordTypeId',
        fieldApiName: SUB_THEME_FIELD
    })
    subThemeFieldInfo({ error, data }) {
        if (data) {
            this.subFieldData = data;
            //get array key for selected theme
            var selectedThemeKey = 0;
            for (var i = 0; i < this.themes.length; i++) {
                if (this.themes[i].value == this.theme) {
                    selectedThemeKey = i;
                }
            }
            this.subthemes = this.subFieldData.values.filter((opt) => opt.validFor.includes(selectedThemeKey));
        }
        else {
            console.log("error: "+error);
        }
    }

    handleThemeChange(event) {
        let key = this.subFieldData.controllerValues[event.target.value];
        this.subthemes = this.subFieldData.values.filter((opt) => opt.validFor.includes(key));

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