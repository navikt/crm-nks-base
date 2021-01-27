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
                console.log(themeGroup.Name);
                themeGroups.push({ label: themeGroup.Name, value: themeGroup.Id });
                //Creating the theme map (ThemegroupId (SF) => [theme CRM_Code__c])
                let groupThemes = [];
                if (data.themeMap[themeGroup.Id]) {
                    groupThemes = data.themeMap[themeGroup.Id].map(theme => {
                        return theme.CRM_Code__c;
                    });
                }
                mappedThemes[themeGroup.Id] = groupThemes;
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
            this.error = true;
            console.log(JSON.stringify(error, null, 2));
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
                return this.themeMap[themeGroup].includes(navCase.sakstema);
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
        return this.selectedCase ? this.selectedCase.sakstema : null;
    }

    @api
    get navCaseType() {
        return this.selectedCaseType;
    }

    get title() {
        return NAV_CASE_TITLE + ' (' + this.caseList.length + ')';
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
        else {
            return {
                isValid: false,
                errorMessage: VALIDATION_ERROR
            };
        }
    }
}