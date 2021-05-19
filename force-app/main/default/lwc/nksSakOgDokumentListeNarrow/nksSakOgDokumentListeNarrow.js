import { LightningElement, api, track } from 'lwc';
import getJournalPosts from '@salesforce/apex/NKS_SafJournalpostListController.getJournalPosts';
import getCategorization from '@salesforce/apex/NKS_ThemeUtils.getCategorization';
import getRecordId from '@salesforce/apex/NKS_SafJournalpostListController.getRecordId';
import getCases from '@salesforce/apex/NKS_SafJournalpostListController.getNavCases';

const QUERY_FIELDS = {
    name: 'journalposter',
    queryFields: [
        { name: 'journalpostId' },
        { name: 'tittel' },
        { name: 'journalposttype' },
        { name: 'journalstatus' },
        { name: 'tema' },
        { name: 'temanavn' },
        { name: 'behandlingstema' },
        { name: 'behandlingstemanavn' },
        { name: 'datoOpprettet' },
        { name: 'antallRetur' },
        { name: 'kanal' },
        { name: 'kanalnavn' },
        {
            name: 'sak',
            queryFields: [{ name: 'fagsakId' }, { name: 'fagsaksystem' }, { name: 'sakstype' }, { name: 'tema' }]
        },
        {
            name: 'avsenderMottaker',
            queryFields: [{ name: 'navn' }]
        },
        {
            name: 'dokumenter',
            queryFields: [
                { name: 'dokumentInfoId' },
                { name: 'tittel' },
                {
                    name: 'dokumentvarianter',
                    queryFields: [
                        { name: 'variantformat' },
                        { name: 'filnavn' },
                        { name: 'filtype' },
                        { name: 'saksbehandlerHarTilgang' },
                        { name: 'skjerming' }
                    ]
                }
            ]
        }
    ]
};

export default class NksSakOgDokumentListeNarrow extends LightningElement {
    _selectedJornalpostTypes = ['I', 'U', 'N']; //The selected Journalpost types to show

    @api recordId; // Id from record page (From UiRecordAPI)
    @api objectApiName; // Value from UiRecordAPI
    @api brukerIdField;
    @api viewedRecordId;
    @api viewedObjectApiName;
    @api relationshipField;
    @api themeGroupField;

    //Query variables
    @track queryVariables = {
        brukerId: {},
        tema: null,
        journalstatuser: ['JOURNALFOERT', 'FERDIGSTILT', 'EKSPEDERT'],
        fraDato: null,
        tilDato: null,
        foerste: 10
    };

    @track errors = [];
    caseStatusArray = [];

    @track themeGroupArr = [
        { label: '', value: '' },
        { label: '', value: '' },
        { label: '', value: '' },
        { label: '', value: '' },
        { label: '', value: '' },
        { label: '', value: '' },
        { label: '', value: '' }
    ];
    @track themeArr = [];
    @track filteredJournalPosts = [];
    @track journalposts = [];
    @track sideInfo;
    @track activeSections = [];
    _selectedTheme;
    themeMap;
    _selectedThemeGroups = '';
    isLoaded = false;

    @api get nmbOfJournalPosts() {
        return this.queryVariables.foerste;
    }
    set nmbOfJournalPosts(value) {
        this.queryVariables.foerste = value;
    }

    set selectedTheme(value) {
        this._selectedTheme = value;
        this.filterJournalposts();
    }

    get hasErrors() {
        return 1 <= this.errors.length ? true : false;
    }

    get isThemeFieldsDisabled() {
        return Array.isArray(this.themeArr) && this.themeArr.length === 0;
    }

    get selectedTheme() {
        return this._selectedTheme;
    }

    get selectedThemeGroups() {
        return this._selectedThemeGroups;
    }

    set selectedThemeGroups(value) {
        this._selectedThemeGroups = value ? value : [];
        this.filterThemes();
        this.selectedTheme = 'all';
    }

    get fromDate() {
        return this.queryVariables.fraDato;
    }

    set fromDate(value) {
        const minDate = new Date('2016-06-04');
        const newDate = new Date(value);
        this.queryVariables.fraDato = value;
        if (minDate > newDate) {
            this.queryVariables.fraDato = '2016-06-04';
        }
        this.callGetJournalPosts(false);
    }

    get toDate() {
        return this.queryVariables.tilDato;
    }

    set toDate(value) {
        this.queryVariables.tilDato = value;
        this.callGetJournalPosts(false);
    }

    connectedCallback() {
        this.init();
    }

    setThemeGroupCheckboxes() {
        let elements = Array.from(this.template.querySelectorAll('lightning-input.themeGroupCheckbox'));

        if (elements && elements.length > 0) {
            if (this.selectedThemeGroups.length === 0) {
                this.setThemeGroupCheckbox('all', true);
            } else {
                this.selectedThemeGroups.forEach((themeGroup) => this.setThemeGroupCheckbox(themeGroup, true));
            }
        }
    }

    async init() {
        if (this.queryVariables.fraDato == null) {
            let d = new Date(Date.now());
            d.setFullYear(d.getFullYear() - 1);
            this.queryVariables.fraDato = d.toISOString().split('T')[0];
        }
        this.callGetJournalPosts(false);
        await this.callGetSelectedTheme();
        await this.callGetThemes();
        this.setThemeGroupCheckboxes();
        this.callGetCases();
    }

    get isEmptyResult() {
        return this.filteredJournalPosts.length === 0 ? true : false;
    }

    queryMoreJournalPosts() {
        this.callGetJournalPosts(true);
    }

    get canLoadMore() {
        if (this.sideInfo) {
            return this.sideInfo.finnesNesteSide;
        }

        return false;
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
            this.themeMap = data.themeMap;
        } catch (err) {
            this.setErrorMessage(err, 'caughtError');
        }
    }

    async callGetSelectedTheme() {
        if (this.themeGroupField) {
            const inputParams = {
                field: this.themeGroupField,
                objectApiName: this.viewedObjectApiName ? this.viewedObjectApiName : this.objectApiName,
                relationshipField: this.relationshipField,
                relationshipValue: this.viewedRecordId ? this.viewedRecordId : this.recordId
            };

            try {
                let data = await getRecordId(inputParams);
                if (data) {
                    this.selectedThemeGroups = [data];
                }
            } catch (err) {
                this.setErrorMessage(err, 'caughtError');
            }
        } else {
            this.selectedThemeGroups = [];
        }
    }

    async callGetJournalPosts(isQueryMore) {
        isQueryMore = this.canLoadMore ? isQueryMore : false;
        this.isLoaded = isQueryMore === true ? true : false;
        this.queryVariables.etter = isQueryMore ? this.sideInfo.sluttpeker : null;
        this.isLoadingMore = isQueryMore;
        const inputParams = {
            brukerIdField: this.brukerIdField,
            objectApiName: this.viewedObjectApiName ? this.viewedObjectApiName : this.objectApiName,
            relationshipField: this.relationshipField,
            viewedRecordId: this.viewedRecordId ? this.viewedRecordId : this.recordId,
            queryVariables: this.queryVariables,
            queryField: QUERY_FIELDS
        };
        this.errors = [];
        try {
            const journalpostData = await getJournalPosts(inputParams);
            if (journalpostData.isSuccess) {
                this.sideInfo = journalpostData.data.dokumentoversiktBruker.sideInfo;
                this.journalposts = isQueryMore
                    ? this.journalposts.concat(journalpostData.data.dokumentoversiktBruker.journalposter)
                    : journalpostData.data.dokumentoversiktBruker.journalposter;
            } else {
                this.sideInfo = null;
                this.journalposts = [];
                this.setErrorMessage(journalpostData.errors[0], 'journalpostError');
            }
            this.filterJournalposts();
        } catch (err) {
            this.setErrorMessage(err, 'caughtError');
        }
        this.isLoaded = true;
        this.isLoadingMore = false;
    }

    async callGetCases() {
        const inputParams = {
            brukerIdField: this.brukerIdField,
            objectApiName: this.viewedObjectApiName ? this.viewedObjectApiName : this.objectApiName,
            relationshipField: this.relationshipField,
            viewedRecordId: this.viewedRecordId ? this.viewedRecordId : this.recordId
        };

        try {
            let data = await getCases(inputParams);
            this.caseStatusArray = [];
            data.forEach((element) => {
                let caseX = this.formatCase(element);
                this.caseStatusArray.push(caseX);

                if (caseX.isOpen) {
                    let jp = this.filteredJournalPosts.find((jpCase) => jpCase.caseId === caseX.caseId);
                    if (jp) {
                        jp.caseTitle += ' (' + caseX.status + ')';
                    }
                }
            });
        } catch (err) {
            this.setErrorMessage(err, 'caughtError');
        }
    }

    formatCase(element) {
        let nmbOfOpen = 0;
        let status = '';
        let isOpen = false;

        element.behandlingskjede.forEach((behandling) => {
            if (behandling.slutt == null) {
                nmbOfOpen++;
                isOpen = true;
            }
        });

        if (isOpen) {
            status = nmbOfOpen + (nmbOfOpen > 1 ? ' åpne henvendelser' : ' åpen henvendelse');
        }

        return { caseId: element.saksId, theme: element.sakstema.value, status: status, isOpen: isOpen };
    }

    filterThemes() {
        let listThemes = [];
        let returnThemes = [];
        let returnCodes = [];

        if (this.themeMap && Array.isArray(this.selectedThemeGroups) && this.selectedThemeGroups.length > 0) {
            this.selectedThemeGroups.forEach(
                (selectedThemeGroup) => (listThemes = listThemes.concat(this.themeMap[selectedThemeGroup]))
            );
        }

        returnThemes.push({ label: 'Alle', value: 'all' });
        listThemes.forEach((theme) => {
            returnThemes.push({ label: theme.Name, value: theme.CRM_Code__c });
            returnCodes.push(theme.CRM_Code__c);
        });

        this.themeArr = returnThemes;
    }

    filterJournalposts() {
        if (Array.isArray(this.themeArr) && this.themeArr.length <= 0) {
            this.filteredJournalPosts = [];
            this.activeSections = [];
            return;
        }

        let caseMap = new Map();
        this.journalposts
            .filter(
                (journalpost) =>
                    ((this.selectedTheme === 'all' && this.themeCodeInThemeArr(journalpost.sak.tema)) ||
                        this.selectedTheme === journalpost.sak.tema) &&
                    this._selectedJornalpostTypes.includes(journalpost.journalposttype)
            )
            .forEach((journalpost) => {
                let key = journalpost.sak.sakstype === 'FAGSAK' ? journalpost.sak.fagsakId : journalpost.sak.tema;
                let caseType = this.saksTypeFormatted(journalpost.sak);
                let caseStatus = this.caseStatusArray.find((element) => element.caseId === key);
                let title =
                    this.themeArr.find((theme) => theme.value === journalpost.sak.tema).label +
                    ': ' +
                    caseType +
                    (journalpost.sak.fagsakId ? ' ' + journalpost.sak.fagsakId : '') +
                    (caseStatus && caseStatus.isOpen ? ' (' + caseStatus.status + ')' : '');

                if (caseMap.has(key)) {
                    caseMap.get(key).journalpostList.push(journalpost);
                } else {
                    caseMap.set(key, { caseId: key, caseTitle: title, journalpostList: [journalpost] });
                }
            });

        this.filteredJournalPosts = Array.from(caseMap.values());
        this.activeSections = Array.from(caseMap.keys());
    }

    caseThemeIsInThemeArr(journalpost) {
        let isAll = this.selectedTheme === 'all';
        let inArr = this.themeCodeInThemeArr(journalpost.sak.tema);

        return isAll && inArr;
    }

    themeCodeInThemeArr(themeCode) {
        let element = this.themeArr.find((theme) => theme.value === themeCode);
        return element ? true : false;
    }

    saksTypeFormatted(sak) {
        let caseType = sak && sak.sakstype ? sak.sakstype : '';
        switch (caseType) {
            case 'FAGSAK':
                return 'Fagsak';
            case 'GENERELL_SAK':
                return 'Generell';
            default:
                return '';
        }
    }

    /**
     * HANDLE INPUTS
     */
    handleJournalpostTypeCheckboxChange() {
        const elements = Array.from(this.template.querySelectorAll('lightning-input.journalpostType'));

        let checked = elements.filter((element) => element.checked).map((element) => element.name);
        this._selectedJornalpostTypes = checked;
        this.filterJournalposts();
    }

    handleJournalpostFromDateChange(event) {
        let fromDate = event.target.value;
        this.fromDate = fromDate;
    }

    handleJournalpostToDateChange(event) {
        let toDate = event.target.value;
        this.toDate = toDate;
    }

    handleThemeGroupCheckboxChange() {
        const elements = Array.from(this.template.querySelectorAll('lightning-input.themeGroupCheckbox'));
        let checked = elements.filter((element) => element.checked).map((element) => element.name);

        if (checked && checked.includes('all')) {
            this.template.querySelectorAll('lightning-input.themeGroupCheckbox').forEach((element) => {
                element.checked = element.name === 'all' ? false : true;
            });
            this.handleThemeGroupCheckboxChange();
        } else {
            this.selectedThemeGroups = checked;
        }
    }

    handleSetSelectedTheme(event) {
        this.selectedTheme = event.target.value;
    }

    setThemeGroupCheckbox(checkboxName, value) {
        let checkbox = Array.from(this.template.querySelectorAll('lightning-input.themeGroupCheckbox')).find(
            (element) => element.name === checkboxName
        );
        checkbox.checked = value;

        this.handleThemeGroupCheckboxChange();
    }

    setErrorMessage(err) {
        this.setErrorMessage(err, '');
    }

    setErrorMessage(err, type) {
        type = err.body && type === 'caughtError' ? 'fetchResponseError' : type;
        switch (type) {
            case 'fetchResponseError':
                if (Array.isArray(error.body)) {
                    this.errors = this.errors.concat(err.body.map((e) => e.message));
                } else if (typeof error.body.message === 'string') {
                    this.errors.push(err.body.message);
                }
                break;
            case 'journalpostError':
                let errorString = '';
                if (err.status) {
                    errorString = err.status + ' ';
                }
                errorString += err.error + ' - ' + err.message;
                this.errors.push(errorString);
                break;
            case 'caughtError':
                this.errors.push('Ukjent feil: ' + err.message);
                break;
            default:
                this.errors.push('Ukjent feil: ' + err);
                break;
        }
    }
}
