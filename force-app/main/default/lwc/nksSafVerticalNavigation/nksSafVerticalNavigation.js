import { LightningElement, api, track } from 'lwc';

export default class NksSafVerticalNavigation extends LightningElement {
    @api availableThemes;
    @api availableProcessThemes;
    @api selectedThemes;
    @api selectedItem = "all";


    @track themeGroups = [];
    themeGroupObj;
    chosenThemeGroup;
    chosenTheme;
    themes;

    connectedCallback() {
        this.selectedItem = (this.selectedItem) ? "all" : this.selectedItem;
    }

    handleSelect(event) {
        this.selectedItem = event.detail.name
        this.createSelectedThemeEvent();
    }

    createSelectedThemeEvent() {
        this.dispatchEvent(new CustomEvent('themeselection', { detail: this.selectedItem }));
    }
}