import { LightningElement, track, api, wire } from 'lwc';
import getCategorization from '@salesforce/apex/NKS_ThemeUtils.getCategorization';

//#### LABEL IMPORTS ####
import VALIDATION_ERROR from '@salesforce/label/c.NKS_Theme_Categorization_Validation_Error';

export default class NksThemeCategorization extends LightningElement {

    @track themeGroups = [];
    @track subThemeMap;
    @track themeMap;
    categories;
    chosenThemeGroup;
    chosenTheme;
    chosenSubtheme;
    subthemes;
    themes;

    @wire(getCategorization, {})
    categoryResults({ data, error }) {
        if (data) {
            this.categories = data;
            let groups = [];
            this.categories.themeGroups.forEach(themeGroup => {
                groups.push({ label: themeGroup.Name, value: themeGroup.Id });
            });

            this.themeGroups = groups;
            this.subThemeMap = data.subthemeMap;
            this.themeMap = data.themeMap;
        }
    }

    handleThemeGroupChange(event) {
        this.chosenThemeGroup = event.detail.value;
        this.chosenTheme = null;
        this.chosenSubtheme = null;

        this.filterThemes();
    }

    handleThemeChange(event) {
        this.chosenTheme = event.detail.value;
        this.chosenSubtheme = null;
        this.filterSubthemes();
    }

    handleSubthemeChange(event) {
        this.chosenSubtheme = event.detail.value;
    }

    @api
    get themeGroup() {
        return this.chosenThemeGroup;
    }

    @api
    get theme() {
        return this.chosenTheme;
    }

    @api
    get subtheme() {
        return this.chosenSubtheme;
    }

    @api
    get themeCode() {
        let themeCode = '';

        let themes = (this.themeGroup && this.themeMap) ? this.themeMap[this.themeGroup] : [];
        for (let theme of themes) {
            if (theme.Id === this.theme) {
                themeCode = theme.CRM_Code__c;
                break;
            }
        }
        return themeCode;
    }

    @api
    get themeGroupCode() {
        let themeGroupCode = '';

        if (this.categories) {
            for (let themeGroup of this.categories.themeGroups) {
                if (themeGroup.Id === this.themeGroup) {
                    themeGroupCode = themeGroup.CRM_Code__c;
                    break;
                }
            }
        }
        return themeGroupCode;
    }

    @api
    get subthemeCode() {
        let subthemeCode;

        let subthemes = this.chosenTheme && Object.keys(this.subThemeMap).length !== 0 ? this.subThemeMap[this.theme] : [];
        for (let subtheme of subthemes) {
            if (subtheme.Id === this.subtheme) {
                subthemeCode = subtheme.CRM_Code__c;
                break;
            }
        }

        return subthemeCode;
    }

    filterThemes() {
        let listThemes = (this.themeGroup && this.themeMap) ? this.themeMap[this.themeGroup] : [];
        let returnThemes = [];
        listThemes.forEach(theme => {
            returnThemes.push({ label: theme.Name, value: theme.Id });
        });
        this.themes = returnThemes;
    }

    filterSubthemes() {
        let listSubthemes = this.chosenTheme && Object.keys(this.subThemeMap).length !== 0 ? this.subThemeMap[this.chosenTheme] : [];
        let returnThemes = [];
        listSubthemes.forEach(subtheme => {
            returnThemes.push({ label: subtheme.Name, value: subtheme.Id });
        });
        this.subthemes = returnThemes;
    }

    //Validation preventing user moving to next screen in flow if state is not valid
    @api
    validate() {
        //All values has to be set in the component
        if (this.themeGroup && this.theme && this.subtheme) {
            return { isValid: true };
        }
        else {
            return {
                isValid: false,
                errorMessage: VALIDATION_ERROR
            };
        }
    }


}