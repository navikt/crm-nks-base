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

    @track isLoading;

    @track errors = [];

    @track themeGroupArr = [];
    @track themeArr = [];
    @track themeCodeArr = [];
    @track caseMap = new Map();
    @track caseMapArray = [];

    _selectedThemeGroup = '';
    _selectedTheme = '';
    _selectedCase = '';
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

    set selectedThemeGroup(value) {
        this._selectedThemeGroup = value ? value : 'all';
        this.filterThemes();
        this.dispatchAvailableThemes();
        this.selectedTheme = 'all';
    }
    set selectedTheme(value) {
        this._selectedTheme = value;
        this.filterCases();
    }
    set selectedCase(value) {
        this._selectedCase = value ? value : 'all';
        this.dispatchSelectedCase();
    }

    connectedCallback() {
        this.loadThemeAndCase();
    }

    async loadThemeAndCase() {
        this.isLoading = true;
        this.error = null;
        await this.callGetCases();
        await this.callGetThemes();
        await this.callGetSelectedTheme();
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
        } else {
            this.selectedThemeGroup = 'all';
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

            this.caseMap.set('all', [
                {
                    label: 'Alle',
                    caseId: 'all',
                    themeCodeCaseId: 'all_all',
                    themeCode: 'all',
                    themeName: '',
                    isOpen: 'all'
                }
            ]);

            data.forEach((element) => {
                let nmbOfOpenCases = this.nmbOfOpenCases(element);
                let isOpen = nmbOfOpenCases > 0 ? true : false;

                let caseLabel = element.saksId;

                if (isOpen) {
                    caseLabel +=
                        ' - (' +
                        nmbOfOpenCases +
                        (nmbOfOpenCases > 1 ? ' åpne henvendelser' : ' åpen henvendelse') +
                        ')';
                }
                // element.saksId +
                //     (isOpen
                //         ? ' (' +
                //           nmbOfOpenCases +
                //           (nmbOfOpenCases > 1 ? ' åpne henvendelser' : ' åpen henvendelse') +
                //           ')'
                //         : '');

                let caseX = {
                    label: caseLabel,
                    caseId: element.saksId,
                    themeCodeCaseId: element.sakstema.value + '_' + element.saksId,
                    themeName: element.themeName,
                    themeCode: element.sakstema.value,
                    isOpen: isOpen,
                    openDate: element.opprettet,
                    closeDate: element.lukket
                };

                if (false === this.caseMap.has(caseX.themeCode)) {
                    let caseAlle = {
                        label: 'Alle',
                        caseId: 'all',
                        themeCodeCaseId: element.sakstema.value + '_all',
                        themeName: element.themeName,
                        themeCode: element.sakstema.value,
                        isOpen: true
                    };

                    let caseGenerell = {
                        label: 'Generell',
                        caseId: 'general',
                        themeCodeCaseId: element.sakstema.value + '_general',
                        themeName: element.themeName,
                        themeCode: element.sakstema.value,
                        isOpen: true
                    };
                    this.caseMap.set(caseX.themeCode, [caseAlle, caseGenerell]);
                }

                this.caseMap.get(caseX.themeCode).push(caseX);
            });
        } catch (err) {
            this.setErrorMessage(err, 'caughtError');
        }
    }

    nmbOfOpenCases(caseX) {
        let nmbOfOpen = 0;

        if (caseX.lukket) {
            return nmbOfOpen;
        }
        caseX.behandlingskjede.forEach((behandling) => {
            if (behandling.slutt == null) {
                nmbOfOpen++;
            }
        });
        return nmbOfOpen;
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
        let caseMapArr = [];

        this.getCaseMapArrayFromCaseMap('all', caseMapArr);

        this.themeCodeArr.forEach((themeCode) => {
            this.getCaseMapArrayFromCaseMap(themeCode, caseMapArr);
        });
        this.caseMapArray = caseMapArr;
        this.selectedCase = caseMapArr[0].value[0].caseId;
    }

    getCaseMapArrayFromCaseMap(themeCode, arr) {
        if (this.caseMap.has(themeCode)) {
            let cases = this.caseMap.get(themeCode);
            let element = { key: themeCode, value: cases, label: cases[0].themeName };

            arr.push(element);
        }
    }

    handleThemeGroupChange(event) {
        this.selectedThemeGroup = event.detail.value;
    }

    handleSelectCaseChange(event) {
        let value = event.detail.name;
        let stringArr = value.split('_');

        this.selectedTheme = stringArr[0];
        this.selectedCase = stringArr[1];
    }

    dispatchAvailableThemes() {
        let value = this.selectedThemeGroup === 'all' ? null : this.themeCodeArr;
        this.dispatchEvent(new CustomEvent('setavailablethemes', { detail: value }));
    }

    dispatchSelectedCase() {
        let caseId = this.selectedCase === 'all' ? null : this.selectedCase;
        let themeCode = this.selectedTheme === 'all' ? null : this.selectedTheme;

        this.dispatchEvent(
            new CustomEvent('selectcase', {
                detail: { caseId: caseId, themeCode: themeCode }
            })
        );
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
