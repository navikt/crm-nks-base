import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getJournalPosts from '@salesforce/apex/NKS_SafJournalpostListController.getJournalPosts';
import getCategorization from '@salesforce/apex/NKS_ThemeUtils.getCategorization';
import getCases from '@salesforce/apex/NKS_SafJournalpostListController.getNavCases';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import PERSON_ACTOR_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';

export default class NksSakOgDokumentListeNarrow extends LightningElement {
    _selectedJornalpostTypes = ['I', 'U', 'N']; //The selected Journalpost types to show
    wireFields;

    @api recordId; // Id from record page (From UiRecordAPI)
    @api objectApiName; // Value from UiRecordAPI
    @api brukerIdField;
    @api viewedRecordId;
    @api viewedObjectApiName;
    @api relationshipField;
    @api themeGroupField;

    //Query variables
    @track queryVariables = {
        brukerId: { id: null, type: 'AKTOERID' },
        tema: null,
        journalstatuser: ['JOURNALFOERT', 'FERDIGSTILT', 'EKSPEDERT'],
        fraDato: null,
        tilDato: null,
        foerste: null
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
    @track availableThemes = [];
    @track filteredJournalPosts = [];
    @track journalposts = [];
    @track sideInfo;
    @track activeSections = [];
    _selectedTheme;
    themeMap;
    _selectedThemeGroups = '';
    isLoaded = false;
    personId;
    journalPostThemeSet = new Set();

    set brukerId(value) {
        this.queryVariables.brukerId.id = value;
        this.callGetJournalPosts(false);
        this.callGetCases();
    }

    get totalNumOfJournalPosts() {
        return this.sideInfo ? this.sideInfo.totaltAntall : 0;
    }

    get lastJournalPostOnPage() {
        return this.filteredJournalPosts.length;
    }

    @api get nmbOfJournalPosts() {
        return this.queryVariables.foerste;
    }

    set nmbOfJournalPosts(value) {
        this.queryVariables.foerste = value;
    }

    set selectedTheme(value) {
        this._selectedTheme = value;
        this.getAvailableThemes();
        this.filterJournalposts();
    }

    getAvailableThemes() {
        this.journalposts.forEach((journalpost) => this.journalPostThemeSet.add(journalpost.sak.tema));
        this.availableThemes = this.themeArr.filter(
            (theme) => true === this.journalPostThemeSet.has(theme.value) || theme.value === 'all'
        );
    }

    get hasErrors() {
        return 1 <= this.errors.length ? true : false;
    }

    get isThemeFieldsDisabled() {
        return Array.isArray(this.availableThemes) && this.availableThemes.length <= 1;
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

    get showAsList() {
        if (
            (this.selectedThemeGroups.length === this.themeGroupArr.length - 1 && this.selectedTheme === 'all') ||
            (this.selectedThemeGroups.length !== this.themeGroupArr.length - 1 && this.selectedTheme === 'all')
        ) {
            return true;
        } else {
            return false;
        }
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

    get journalpostList() {
        filteredJournalPosts.forEach;
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
            this.queryVariables.fraDato = new Date().getFullYear() - 1 + '-01-01';
        }
        await this.callGetThemes();

        this.wireFields = [this.objectApiName + '.Id'];
        if (this.themeGroupField) {
            this.wireFields.push(this.objectApiName + '.' + this.themeGroupField);
        }
        this.getRelatedRecordId(this.brukerIdField, this.objectApiName);
        this.setThemeGroupCheckboxes();
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
            let objThemeGroup = getFieldValue(data, this.objectApiName + '.' + this.themeGroupField);
            if (objThemeGroup) {
                this.selectedThemeGroups = [objThemeGroup];
            }
            this.setThemeGroupCheckboxes();
            if (this.brukerIdField && this.objectApiName) {
                this.getRelatedRecordId(this.brukerIdField, this.objectApiName);
            }
        }
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: [PERSON_ACTOR_FIELD]
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            this.brukerId = getFieldValue(data, PERSON_ACTOR_FIELD);
        }
        if (error) {
            this.setErrorMessage(error, 'caughtError');
        }
    }

    getRelatedRecordId(relationshipField, objectApiName) {
        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: relationshipField,
            objectApiName: objectApiName
        })
            .then((record) => {
                this.personId = this.resolve(relationshipField, record);
                if (null == this.personId) {
                    this.brukerId = null;
                }
            })
            .catch((error) => {
                this.setErrorMessage(error, 'caughtError');
            });
    }

    get isEmptyResult() {
        return this.filteredJournalPosts.length === 0 ? true : false;
    }

    refresh() {
        this.callGetJournalPosts(false);
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

    async callGetJournalPosts(isQueryMore) {
        isQueryMore = this.canLoadMore ? isQueryMore : false;
        this.isLoaded = isQueryMore === true ? true : false;
        this.queryVariables.etter = isQueryMore ? this.sideInfo.sluttpeker : null;
        this.isLoadingMore = isQueryMore;
        const inputParams = {
            queryString: JSON.stringify(this.queryVariables)
        };

        this.errors = [];
        if (this.queryVariables.brukerId.id) {
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
                this.getAvailableThemes();
                this.filterJournalposts();
            } catch (err) {
                this.setErrorMessage(err, 'caughtError');
            }
        } else {
            this.sideInfo = null;
            this.journalposts = [];
            this.filterJournalposts();
        }
        this.isLoaded = true;
        this.isLoadingMore = false;
    }

    async callGetCases() {
        const inputParams = {
            actorId: this.queryVariables.brukerId.id
        };
        if (this.queryVariables.brukerId.id) {
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

        if (this.themeMap && Array.isArray(this.selectedThemeGroups) && this.selectedThemeGroups.length > 0) {
            this.selectedThemeGroups.forEach(
                (selectedThemeGroup) => (listThemes = listThemes.concat(this.themeMap[selectedThemeGroup]))
            );
        }
        listThemes.sort(this.compareListThemes);

        returnThemes.push({ label: 'Alle', value: 'all' });
        listThemes.forEach((theme) => {
            returnThemes.push({ label: theme.Name, value: theme.CRM_Code__c });
        });
        this.themeArr = returnThemes;
    }

    compareListThemes(a, b) {
        const nameA = a.Name.toUpperCase();
        const nameB = b.Name.toUpperCase();

        if (nameA > nameB) {
            return 1;
        }

        if (nameA < nameB) {
            return -1;
        }

        return 0;
    }

    filterJournalposts() {
        if (Array.isArray(this.themeArr) && this.themeArr.length <= 0) {
            this.filteredJournalPosts = [];
            return;
        }

        let caseMap = new Map();
        let journalpostOrderedList = [];
        let journalpostThemes = new Set();
        this.journalposts
            .filter(
                (journalpost) =>
                    ((this.selectedTheme === 'all' && this.themeCodeInThemeArr(journalpost.sak.tema)) ||
                        this.selectedTheme === journalpost.sak.tema) &&
                    this._selectedJornalpostTypes.includes(journalpost.journalposttype)
            )
            .forEach((journalpost) => {
                journalpostThemes.add(journalpost.sak.tema);
                if (this.showAsList === true) {
                    journalpostOrderedList.push(journalpost);
                } else {
                    this.addJournalpostToMap(caseMap, journalpost);
                }
            });

        this.filteredJournalPosts = this.showAsList === true ? journalpostOrderedList : Array.from(caseMap.values());
    }

    addJournalpostToMap(caseMap, journalpost) {
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
                if (Array.isArray(err.body)) {
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

    resolve(path, obj) {
        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || self);
    }
}
