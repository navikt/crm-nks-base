import { LightningElement, track, api, wire } from 'lwc';
import getThemes from '@salesforce/apex/NKS_ThemeUtils.getThemes';
import getSubthemes from '@salesforce/apex/NKS_ThemeUtils.getSubthemes';

//#### LABEL IMPORTS ####
import VALIDATION_ERROR from '@salesforce/label/c.NKS_Theme_Categorization_Validation_Error';

export default class NksThemeCategorization extends LightningElement {

    @track themeGroups = [];
    @track subThemeMap;
    themeGroupObj;
    chosenThemeGroup;
    chosenTheme;
    chosenSubtheme;
    subthemes;
    themes;


    @wire(getThemes, {})
    themeResults({ data, error }) {
        if (data) {
            this.themeGroupObj = data;
            let groups = [];
            for (const [key, value] of Object.entries(data)) {
                if (groups.some(group => group['value'] === key)) {
                    //Theme group already added
                }
                else {
                    groups.push({ label: value[0].themeGroupLabel, value: key });
                }
            }
            this.themeGroups = groups;
        }
    }

    @wire(getSubthemes, {})
    subthemeResults({ data, error }) {
        if (data) {
            this.subThemeMap = data;
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

    filterThemes() {
        let listThemes = (this.themeGroup && this.themeGroupObj) ? this.themeGroupObj[this.themeGroup] : [];
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