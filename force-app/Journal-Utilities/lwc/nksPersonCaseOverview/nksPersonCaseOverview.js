import { LightningElement, api, wire } from 'lwc';
import getCases from '@salesforce/apex/NKS_NavCaseService.getNavCases';
import getCategorization from '@salesforce/apex/NKS_ThemeUtils.getCategorization';
import nksSingleValueUpdate from '@salesforce/messageChannel/nksSingleValueUpdate__c';

import { publish, MessageContext } from 'lightning/messageService';

//##LABEL IMPORTS
import NAV_CASE_TITLE from '@salesforce/label/c.NKS_NAV_Case_Title';
import VALIDATION_ERROR from '@salesforce/label/c.NKS_NAV_Case_Validation_Error';
import NAV_CASE_RETRIEVE_ERROR from '@salesforce/label/c.NKS_NAV_Case_Retrieve_Error';

export default class NksPersonCaseOverview extends LightningElement {

    @api labels = {
        NAV_CASE_TITLE,
        VALIDATION_ERROR,
        NAV_CASE_RETRIEVE_ERROR
    }

    @api actorId;
    caseList = []; //Contains all NAV cases returned from the API
    displayedCases = []; //Holds the list of cases to be displayed
    selectedCase;
    themeGroupOptions = [];
    filteredThemes = [];
    themeMap;
    dataLoaded = false;
    error = false;
    selectedCaseType = 'FAGSAK'; //Default value

    caseTypeOptions = [
        { label: 'Fagsak', value: 'FAGSAK' },
        { label: 'Generell', value: 'GENERELL_SAK' }
    ];

    renderedCallback() {
        this.setSelectedNavCase(this.selectedCaseId);
    }

    @wire(MessageContext)
    messageContext;

    @wire(getCategorization, {})
    categoryResults({ data, error }) {
        if (data) {
            let themeGroups = [{ label: 'Alle', value: 'ALL' }];
            let mappedThemes = {};

            data.themeGroups.forEach(themeGroup => {
                themeGroups.push({ label: themeGroup.Name, value: themeGroup.Id });
                //Creating the theme map (ThemegroupId (SF) => [{ themeCode: code, themeSfId: id}])
                let groupThemes = {};
                groupThemes.themes = [];
                if (data.themeMap[themeGroup.Id]) {
                    groupThemes.themes = data.themeMap[themeGroup.Id].map(theme => {
                        return { themeCode: theme.CRM_Code__c, themeSfId: theme.Id };
                    });
                }
                //Property function to determine if the group of themes includes an input theme
                groupThemes.hasTheme = (inputTheme) => {
                    let returnTheme = null;
                    for (let idx = 0; idx < groupThemes.themes.length; idx++) {
                        const theme = groupThemes.themes[idx];
                        if (theme.themeCode == inputTheme) {
                            returnTheme = theme;
                            break;
                        }
                    }
                    return returnTheme;
                };
                mappedThemes[themeGroup.Id] = groupThemes;
                mappedThemes.getTheme = (inputTheme) => {
                    let returnTheme = null;
                    for (const themeGroupId in mappedThemes) {
                        if (mappedThemes.hasOwnProperty(themeGroupId)) {
                            returnTheme = mappedThemes[themeGroupId].hasOwnProperty('hasTheme') ? mappedThemes[themeGroupId].hasTheme(inputTheme) : null;
                            if (returnTheme !== null) break;
                        }
                    }
                    return returnTheme;
                }
            });


            this.themeGroupOptions = themeGroups;
            this.themeMap = mappedThemes;
        }
    }

    @wire(getCases, { actorId: '' })
    wireUser({
        error,
        data
    }) {
        if (data) {
            this.caseList = data;
            this.displayedCases = this.caseList;
        }
        else {
            if (error) console.log(JSON.stringify(error, null, 2));
        }
        this.dataLoaded = data || error;
        this.error = !data && error;
    }

    //Handles the nksNavCaseItem click event and updates the selected attribute for all the childs
    handleCaseSelected(event) {
        let selectedNavCaseId = event.detail.selectedCase.saksId;
        this.selectedCase = event.detail.selectedCase;

        this.setSelectedNavCase(selectedNavCaseId);
        this.publishFieldChange('themeCode', this.selectedCaseTheme);
    }

    setSelectedNavCase(selectedNavCaseId) {
        let caseItems = this.template.querySelectorAll('c-nks-nav-case-item');
        caseItems.forEach(caseItem => {
            caseItem.selected = caseItem.navCase.saksId == selectedNavCaseId ? true : false;
        });
    }

    handleFilterChange(event) {
        let themeGroup = event.target.value;

        if (themeGroup === 'ALL') {
            this.displayedCases = this.caseList;
            return;
        }
        else {
            this.displayedCases = this.caseList.filter(navCase => {
                return this.themeMap[themeGroup].hasTheme(navCase.sakstema.value) !== null;
            })
        }
    }

    handleCaseTypeChange(event) {
        this.selectedCase = null;
        this.selectedCaseType = event.detail.value;
    }

    //Publish to nksWorkAllocation component to trigger search in flow context
    publishFieldChange(field, value) {
        const payload = { name: field, value: value };
        publish(this.messageContext, nksSingleValueUpdate, payload);
    }

    @api
    get selectedCaseId() {
        return this.selectedCase ? this.selectedCase.saksId : null;
    }

    @api
    get selectedCaseTheme() {
        if (this.isGeneralCase === true) {
            let themeCmp = this.template.querySelector('c-nks-theme-categorization');
            return themeCmp.themeCode;
        }
        else {
            return this.selectedCase ? this.selectedCase.sakstema.value : null;
        }
    }

    @api
    get selectedCaseThemeSfId() {
        if (this.isGeneralCase === true) {
            let themeCmp = this.template.querySelector('c-nks-theme-categorization');
            return themeCmp.theme;
        }
        else {
            let returnTheme = this.themeMap ? this.themeMap.getTheme(this.selectedCaseTheme) : null;
            return returnTheme !== null ? returnTheme.themeSfId : null;
        }
    }

    @api
    get selectedThemeGroupSfId() {
        let themeGroupSfId;

        if (this.isGeneralCase === true) {
            let themeCmp = this.template.querySelector('c-nks-theme-categorization');
            themeGroupSfId = themeCmp.themeGroup;
        }
        else {
            if (this.themeMap) {
                Object.keys(this.themeMap).forEach(themeGroupId => {
                    if (this.themeMap[themeGroupId].hasOwnProperty('hasTheme')) {
                        if (this.themeMap[themeGroupId].hasTheme(this.selectedCaseTheme) !== null) themeGroupSfId = themeGroupId;
                    }
                });
            }
        }
        return themeGroupSfId;
    }

    @api
    get navCaseType() {
        return this.selectedCaseType;
    }

    //When GENERELL_SAK is chosen, the agent has the ability to also select a subtheme for the journal entry
    @api
    get selectedSubthemeSfId() {
        let subtheme = '';
        if (this.isGeneralCase === true) {
            let themeCmp = this.template.querySelector('c-nks-theme-categorization');
            subtheme = themeCmp.subtheme;
        }
        return subtheme;
    }

    @api
    get selectedSubtheme() { }

    get isGeneralCase() {
        return this.selectedCaseType === 'GENERELL_SAK';
    }

    get title() {
        return NAV_CASE_TITLE + ' (' + this.caseList.length + ')';
    }

    get showCases() {
        return this.hasCases && !this.isGeneralCase;
    }

    get hasCases() {
        return this.dataLoaded && this.caseList.length !== 0;
    }

    @api
    validate() {
        //Theme and theme group must be set
        if (this.selectedCase) {
            return { isValid: true };
        }
        else if (this.isGeneralCase === true) {
            let themeCmp = this.template.querySelector('c-nks-theme-categorization');
            return themeCmp.validate();
        }
        else {
            return {
                isValid: false,
                errorMessage: VALIDATION_ERROR
            };
        }
    }
}