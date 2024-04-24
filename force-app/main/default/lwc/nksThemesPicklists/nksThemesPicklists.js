import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import NAV_TASK_OBJECT from '@salesforce/schema/NavTask__c';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import SUB_THEME_FIELD from '@salesforce/schema/NavTask__c.CRM_SubTheme__c';
import THEME_FIELD from '@salesforce/schema/NavTask__c.CRM_Theme__c';

export default class NksThemesPicklists extends LightningElement {
    @api theme;
    @api subTheme;

    themes;
    subthemes;
    objectApiName;
    employerRecordTypeId;
    _selectedTheme;
    _selectedSubTheme;

    @api
    get selectedTheme() {
        return this._selectedTheme;
    }

    set selectedTheme(value) {
        this._selectedTheme = value;
    }

    @api
    get selectedSubTheme() {
        return this._selectedSubTheme;
    }

    set selectedSubTheme(value) {
        this._selectedSubTheme = value;
    }

    @wire(getObjectInfo, { objectApiName: NAV_TASK_OBJECT })
    getobjectInfo(result) {
        if (result.data) {
            const rtis = result.data.recordTypeInfos;
            this.employerRecordTypeId = Object.keys(rtis).find((rti) => rtis[rti].name === 'Employer');
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$employerRecordTypeId',
        fieldApiName: THEME_FIELD
    })
    themeFieldInfo({ data }) {
        if (data) this.themes = data.values;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$employerRecordTypeId',
        fieldApiName: SUB_THEME_FIELD
    })
    subThemeFieldInfo({ error, data }) {
        if (data) {
            this.subFieldData = data;
            let selectedThemeKey = 0;
            if (this.themes == null) {
                return;
            }
            this.themes.forEach((theme) => {
                if (theme.value === this.theme) {
                    selectedThemeKey = theme;
                }
            });
            this.subthemes = this.subFieldData.values.filter((opt) => opt.validFor.includes(selectedThemeKey));
        } else {
            console.error('error: ' + error);
        }
    }

    handleThemeChange(event) {
        let key = this.subFieldData.controllerValues[event.target.value];
        this.subthemes = this.subFieldData.values.filter((opt) => opt.validFor.includes(key));

        this._selectedTheme = event.detail.value;
        const selectedThemeEvent = new CustomEvent('themechange', {
            detail: this.selectedTheme
        });
        this.dispatchEvent(selectedThemeEvent);
    }

    handleSubThemeChange(event) {
        this._selectedSubTheme = event.detail.value;
        const selectedSubThemeEvent = new CustomEvent('subthemechange', {
            detail: this.selectedSubTheme
        });
        this.dispatchEvent(selectedSubThemeEvent);
    }
}
