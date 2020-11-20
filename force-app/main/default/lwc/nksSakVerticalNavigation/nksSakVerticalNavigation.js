import { LightningElement, api, track, wire } from 'lwc';
import getThemes from '@salesforce/apex/NKS_ThemeUtils.getThemes';
import { getRecord } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import RecordTypeId from '@salesforce/schema/Account.RecordTypeId';

const PICKLIST_VALUE_ALLE = { label: 'Alle', value: null };

export default class NksSakVerticalNavigation extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api selectedThemeApiName;
    @api selectedThemeGroupApiName;

    @api saker = [
        {
            name: "Ajourholde – Grunnopplysninge",
            id: "ARB"
        },
        {
            name: "Arbeidsavklaringspenger",
            id: "AAP"
        },
        {
            name: "Barnetrygd",
            id: "BT"
        },
        {
            name: "Bidrag",
            id: "BI"
        }
    ];

    @api availableThemes;
    @api selectedThemes;
    @api selectedItem = "all";


    @track themeGroups = [];
    themeGroupObj;
    chosenThemeGroup;
    chosenTheme;
    themes;


    // @wire(getRecord, { recordId: '$recordId', fields: ['$selectedThemeApiName', '$selectedThemeGroupApiName'] }) parentRecord;
    // @wire(getPicklistValues, { recordTypeId: '$parentRecord.data.recordTypeId', fieldApiName: '$selectedThemeGroupApiName' })
    // setPicklistValues(data, error) {
    //     if (data) {
    //         this.themeGroups = [PICKLIST_VALUE_ALLE];
    //         this.themeGroups = this.themeGroups.concat(data.values);

    //         if (null == this.chosenThemeGroup) {
    //             this.chosenThemeGroup = data.defaultValue;
    //         }
    //     }
    // }


    // @wire(getThemes, {})
    // themeResults({ data, error }) {
    //     if (data) {
    //         this.themeGroupObj = data;
    //         let groups = [];
    //         for (const [key, value] of Object.entries(data)) {
    //             if (groups.some(group => group['value'] === key)) {
    //                 //Theme group already added
    //             }
    //             else {
    //                 groups.push({ label: value[0].themeGroupLabel, value: key });
    //             }
    //         }
    //         this.themeGroups = groups;
    //     }
    // }

    // handleThemeGroupChange(event) {
    //     this.chosenThemeGroup = event.detail.value;
    //     this.chosenTheme = null;

    //     this.filterThemes();
    // }

    // filterThemes() {
    //     let listThemes = (this.themeGroup && this.themeGroupObj) ? this.themeGroupObj[this.themeGroup] : [];
    //     let returnThemes = [];
    //     listThemes.forEach(theme => {
    //         if(theme.)
    //         returnThemes.push({ label: theme.Name, value: theme.Id });
    //     });
    //     this.themes = returnThemes;
    // }

    connectedCallback() {
        this.selectedItem = (this.selectedItem) ? "all" : this.selectedItem;
        this.getThemes();
    }

    getThemes() {
        console.log(this.recordId);
        console.log(this.selectedThemeApiName);
        console.log(this.selectedThemeGroupApiName);
        try {
            const record = getRecord({ recordId: this.recordId, fields: [this.selectedThemeApiName, this.selectedThemeGroupApiName] });
            console.log(record.data.recordTypeId);
            console.log(this.selectedThemeGroupApiName);
            const themesGroupResult = getPicklistValues({ recordTypeId: record.data.recordTypeId, fieldApiName: this.selectedThemeGroupApiName });

            if (themesGroupResult) {
                this.themeGroups = [PICKLIST_VALUE_ALLE];
                this.themeGroups = this.themeGroups.concat(themesGroupResult.values);

                if (null == this.chosenThemeGroup) {
                    this.chosenThemeGroup = themesGroupResult.defaultValue;
                }
            }
        } catch (error) {
            console.log(error);
        }
    }

    handleSelect(event) {
        this.selectedItem = event.detail.name
        this.createSelectedThemeEvent();
    }

    createSelectedThemeEvent() {
        this.dispatchEvent(new CustomEvent('themeselection', { detail: this.selectedItem }));
    }

}