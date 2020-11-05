import { LightningElement, track, api, wire } from 'lwc';
import getThemes from '@salesforce/apex/NKS_ThemeUtils.getThemes';
import getSubthemes from '@salesforce/apex/NKS_ThemeUtils.getSubthemes';

export default class NksThemeCategorization extends LightningElement {

    @api themeGroup;
    @api theme;
    @api subtheme;
    @track themeGroups = [];
    @track subThemeMap;
    themeGroupObj;


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
        this.themeGroup = event.detail.value;
    }

    handleThemeChange(event) {
        this.theme = event.detail.value;
    }

    handleSubthemeChange(event) {
        this.subtheme = event.detail.value;
    }

    get themes() {
        let listThemes = (this.themeGroup && this.themeGroupObj) ? this.themeGroupObj[this.themeGroup] : [];
        let returnThemes = [];
        listThemes.forEach(theme => {
            returnThemes.push({ label: theme.Name, value: theme.Id });
        });
        return returnThemes;
    }

    get subthemes() {
        let listSubthemes = this.theme ? this.subThemeMap[this.theme] : [];
        let returnThemes = [];
        listSubthemes.forEach(subtheme => {
            returnThemes.push({ label: subtheme.Name, value: subtheme.Id });
        });
        return returnThemes;
    }


}