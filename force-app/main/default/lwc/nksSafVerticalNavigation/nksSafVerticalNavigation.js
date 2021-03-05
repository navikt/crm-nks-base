import { LightningElement, api, track } from 'lwc';
import getCategorization from '@salesforce/apex/NKS_ThemeUtils.getCategorization';
import getCases from '@salesforce/apex/NKS_SafJournalpostListController.getNavCases';
import getRecordId from '@salesforce/apex/NKS_SafJournalpostListController.getRecordId';

export default class NksSafVerticalNavigation extends LightningElement {
    @api objectApiName;
    @api recordId;

    @api get themeGroupField() {
        return this._themeGroupField;
    }

    @api get viewedObjectApiName() {
        return this._viewedObjectApiName ? this._viewedObjectApiName : this.objectApiName;
    }
    @api get viewedRecordId() {
        return this._viewedRecordId ? this._viewedRecordId : this.recordId;
    }
    @api get brukerIdField() {
        return this._brukerIdField;
    }
    @api get relationshipField() {
        return this._relationshipField;
    }

    set themeGroupField(value) {
        this._themeGroupField = value ? value : null;
    }
    set viewedObjectApiName(value) {
        this._viewedObjectApiName = value ? value : this.objectApiName;
    }
    set viewedRecordId(value) {
        this._viewedRecordId = value ? value : this.recordId;
    }
    set brukerIdField(value) {
        this._brukerIdField = value;
    }
    set relationshipField(value) {
        this._relationshipField = value;
    }

    _themeGroupField;
    _viewedObjectApiName;
    _viewedRecordId;
    _brukerIdField;
    _relationshipField;

    isLoading;

    @track errors = [];

    @track themeGroupArr = [];
    @track themeArr = [];
    @track themeCodeArr = [];
    @track caseMap;
    @track caseArr = [];

    _selectedThemeGroup = 'all';
    _selectedTheme = 'all';
    _selectedCase;
    _themeMap;

    get selectedThemeGroup() {
        return this._selectedThemeGroup;
    }
    get selectedTheme() {
        return this._selectedTheme;
    }
    get selectedCase() {
        return this._selectedCase;
    }

    // get isThemeSelectionDisabled() { return this.selectedThemeGroup === 'all' ? true : false; }

    set selectedThemeGroup(value) {
        this._selectedThemeGroup = value ? value : all;
        this.filterThemes();
        this.dispatchAvailableThemes();
        this.selectedTheme = 'all';
    }
    set selectedTheme(value) {
        this._selectedTheme = value;
        this.filterCases();
    }
    set selectedCase(value) {
        if (this._selectedCase === value) {
            return;
        }
        this._selectedCase = value ? value : 'all';
        this.dispatchSelectedCase();
    }

    connectedCallback() {
        this.loadThemeAndCase();
    }

    async loadThemeAndCase() {
        this.isLoading = true;
        this.error = null;
        await this.callGetThemes();
        await this.callGetCases();
        await this.callGetSelectedTheme();
        //this.selectedThemeGroup = 'all';
        this.isLoading = false;
    }

    async callGetSelectedTheme() {
        if (this.themeGroupField) {
            const inputParams = {
                field: this.themeGroupField,
                objectApiName: this.viewedObjectApiName,
                relationshipField: 'Id',
                relationshipValue: this.viewedRecordId
            };

            this.error = null;

            try {
                let data = await getRecordId(inputParams);
                this.selectedThemeGroup = data;
            } catch (err) {
                this.setErrorMessage(err, 'caughtError');
            }
        }
    }

    async callGetCases() {
        const inputParams = {
            brukerIdField: this.brukerIdField,
            objectApiName: this.viewedObjectApiName,
            relationshipField: this.relationshipField,
            viewedRecordId: this.viewedRecordId
        };

        try {
            let data = await getCases(inputParams);
            this.caseMap = new Map();
            data.forEach((element) => {
                let caseX = {
                    label: element.themeName + ' - ' + element.saksId,
                    caseId: element.saksId,
                    themeName: element.themeName,
                    themeCode: element.sakstema.value,
                    isOpen: element.lukket ? false : true,
                    openDate: element.opprettet,
                    closeDate: element.lukket
                };

                if (false === this.caseMap.has(caseX.themeCode)) {
                    this.caseMap.set(caseX.themeCode, []);
                }

                this.caseMap.get(caseX.themeCode).push(caseX);
            });
        } catch (err) {
            this.setErrorMessage(err, 'caughtError');
        }
    }

    async callGetThemes() {
        try {
            const data = await getCategorization();

            this.categories = data;
            let groups = [];
            groups.push({ label: 'Alle', value: 'all' });
            this.categories.themeGroups.forEach((themeGroup) => {
                groups.push({ label: themeGroup.Name, value: themeGroup.Id });
            });

            this.themeGroupArr = groups;
            this._themeMap = data.themeMap;
        } catch (err) {
            this.setErrorMessage(err, 'caughtError');
        }
    }

    filterThemes() {
        let listThemes = [];

        if (this._themeMap && this.selectedThemeGroup === 'all') {
            Object.values(this._themeMap).forEach((list) => (listThemes = listThemes.concat(list)));
        } else {
            listThemes =
                this.selectedThemeGroup &&
                this._themeMap &&
                this.selectedThemeGroup in this._themeMap
                    ? this._themeMap[this.selectedThemeGroup]
                    : [];
        }

        let returnThemes = [];
        let returnCodes = [];
        returnThemes.push({ label: 'Alle', value: 'all' });
        listThemes.forEach((theme) => {
            returnThemes.push({ label: theme.Name, value: theme.CRM_Code__c });
            returnCodes.push(theme.CRM_Code__c);
        });
        this.themeArr = returnThemes;
        this.themeCodeArr = returnCodes;
    }

    filterCases() {
        let listCases = [];

        this.themeCodeArr.forEach((themeCode) => {
            if (this.caseMap.has(themeCode)) {
                listCases = listCases.concat(this.caseMap.get(themeCode));
            }
        });

        listCases.push({
            caseId: 'gs',
            label: 'Generell Sak',
            isOpen: true
        });

        if (listCases.length > 2) {
            listCases.splice(0, 0, {
                caseId: 'all',
                label: 'Alle',
                isOpen: true
            });
        }

        this.caseArr = listCases;
        this.selectedCase = listCases.length > 0 ? listCases[0].caseId : null;
    }

    handleThemeGroupChange(event) {
        this.selectedThemeGroup = event.detail.value;
    }

    // handleThemeChange(event) {
    //     this.selectedTheme = event.detail.value
    // }

    handleSelectCaseChange(event) {
        this.selectedCase = event.detail.name;
    }

    dispatchAvailableThemes() {
        let value = this.selectedThemeGroup === 'all' ? null : this.themeCodeArr;
        this.dispatchEvent(new CustomEvent('setavailablethemes', { detail: value }));
    }

    dispatchSelectedCase() {
        let value = this.selectedCase === 'all' ? null : this.selectedCase;
        this.dispatchEvent(new CustomEvent('selectcase', { detail: value }));
    }

    setErrorMessage(error, type) {
        type = error.body && type === 'caughtError' ? 'fetchResponseError' : type;

        switch (type) {
            case 'fetchResponseError':
                if (Array.isArray(error.body)) {
                    this.errors = this.errors.concat(error.body.map((e) => e.message));
                } else if (typeof error.body.message === 'string') {
                    this.errors.push(error.body.message);
                }
                break;
            case 'journalpostError':
                let errorString = '';

                if (error.status) {
                    errorString = error.status + ' ';
                }
                errorString += error.error + ' - ' + error.message;

                this.errors.push(errorString);
                break;
            case 'caughtError':
                this.errors.push('Ukjent feil: ' + error.message);
                break;
            default:
                this.errors.push('Ukjent feil: ' + err);
                break;
        }
    }
}
