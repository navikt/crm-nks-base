import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getJournalPosts from '@salesforce/apex/NKS_SafJournalpostListController.getJournalPosts';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import PERSON_ACTOR_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';
export default class NksSafJournalpostList extends LightningElement {
    @api recordId; // Id from record page (From UiRecordAPI)
    @api objectApiName; // Value from UiRecordAPI
    wireFields;

    // tracked resources
    @track journalposts = [];
    @track filteredJournalPosts = [];
    @track errors = [];
    @track sideInfo;

    isLoaded = false;
    isLoadingMore = false;

    _relationshipField = null; // Field api name if the recordId is to be set via relationship
    _brukerIdField; //Field pointing to the user id
    _selectedJornalpostTypes = ['I', 'U', 'N']; //The selected Journalpost types to show
    _viewedObjectApiName; // API name of the object to display information from
    _viewedRecordId; // Id of the record to display information for
    availableThemes = null;
    selectedCase = null;
    selectedThemeCode = null;
    personId;

    //Query variables
    @track queryVariables = {
        brukerId: { id: null, type: 'AKTOERID' },
        tema: null,
        journalstatuser: ['JOURNALFOERT', 'FERDIGSTILT', 'EKSPEDERT'],
        fraDato: null,
        tilDato: null,
        foerste: 10
    };

    @api get nmbOfJournalPosts() {
        return this.queryVariables.foerste;
    }
    set nmbOfJournalPosts(value) {
        this.queryVariables.foerste = value;
    }

    @api get selectedJornalpostTypes() {
        return this._selectedJornalpostTypes;
    }

    @api get selectedTema() {
        return this.queryVariables.tema;
    }

    @api get themeGroupField() {
        return this._themeGroupField ? this._themeGroupField : null;
    }

    set themeGroupField(value) {
        this._themeGroupField = value ? value : null;
    }

    @api get viewedObjectApiName() {
        return this._viewedObjectApiName ? this._viewedObjectApiName : this.objectApiName;
    }
    set viewedObjectApiName(value) {
        this._viewedObjectApiName = value ? value : this.objectApiName;
    }

    @api get viewedRecordId() {
        return this._viewedRecordId ? this._viewedRecordId : this.recordId;
    }
    set viewedRecordId(value) {
        this._viewedRecordId = value ? value : this.recordId;
    }

    @api get brukerIdField() {
        return this._brukerIdField;
    }
    set brukerIdField(value) {
        this._brukerIdField = value;
    }

    @api get relationshipField() {
        return this._relationshipField;
    }

    set relationshipField(value) {
        this._relationshipField = value;
    }

    set brukerId(value) {
        this.queryVariables.brukerId.id = value;
        this.callGetJournalPosts(false);
    }

    get brukerId() {
        return this.queryVariables.brukerId.id;
    }

    get hasErrors() {
        return 1 <= this.errors.length ? true : false;
    }
    get canLoadMore() {
        if (this.sideInfo) {
            return this.sideInfo.finnesNesteSide;
        }

        return false;
    }

    get isEmptyResult() {
        return this.filteredJournalPosts.length === 0 ? true : false;
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

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
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
            this.error = true;
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
                console.log(error);
            });
    }

    getHasJournalposttype(statusElement) {
        return this._selectedJornalpostTypes.includes(statusElement);
    }

    setJournalpostTypeCheckBoxes() {
        Array.from(this.template.querySelectorAll('lightning-input.journalpostType')).forEach((element) => {
            this.getJournalposttype(element.name);
        });
    }

    setJournalposttype(value, statusElement) {
        if (value !== this.getJournalposttype(statusElement)) {
            let statuses = this._selectedJornalpostTypes.filter((element) => element !== statusElement);

            if (value === true) {
                statuses = statuses.push(statusElement);
            }

            this._selectedJornalpostTypes = statuses;
        }
    }

    connectedCallback() {
        if (this.queryVariables.fraDato == null) {
            let d = new Date(Date.now());
            d.setFullYear(d.getFullYear() - 1);
            this.queryVariables.fraDato = d.toISOString().split('T')[0];
        }
        this.isLoaded = true;
        this.wireFields = [this.objectApiName + '.Id', this.objectApiName + '.' + this.relationshipField];
        this.getRelatedRecordId(this.brukerIdField, this.objectApiName);
    }

    /**
     * Get the last journalpostId in the journalpost list and add this to the query variables
     */
    queryMoreJournalPosts() {
        this.callGetJournalPosts(true);
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
                this.filterAllJournalposts();
            } catch (err) {
                this.setErrorMessage(err, 'caughtError');
            }
        } else {
            this.sideInfo = null;
            this.journalposts = [];
            this.filterAllJournalposts();
        }
        this.isLoaded = true;
        this.isLoadingMore = false;
    }

    handleJournalpostTypeCheckboxChange() {
        const elements = Array.from(this.template.querySelectorAll('lightning-input.journalpostType'));

        let checked = elements.filter((element) => element.checked).map((element) => element.name);
        this._selectedJornalpostTypes = checked;
        this.filterAllJournalposts();
    }

    handleAvailableThemes(event) {
        this.availableThemes = event.detail;
        this.filterAllJournalposts();
    }

    handleSelectCase(event) {
        this.selectedCase = event.detail.caseId;
        this.selectedThemeCode = event.detail.themeCode;
        this.filterAllJournalposts();
    }

    handleJournalpostFromDateChange(event) {
        let fromDate = event.target.value;
        this.fromDate = fromDate;
    }

    handleJournalpostToDateChange(event) {
        let toDate = event.target.value;
        this.toDate = toDate;
    }

    /**
     * Set filteredJournalPosts to all journals where tema is matching the selected temas (or temalist is empty == alle tema) AND the journalpost type is matching
     */
    filterAllJournalposts() {
        this.filteredJournalPosts = this.journalposts.filter(
            (journalpost) =>
                (this.availableThemes == null || this.availableThemes.includes(journalpost.tema)) &&
                (this.selectedCase == null ||
                    this.selectedCase === journalpost.sak.fagsakId ||
                    (this.selectedCase === 'general' && 'GENERELL_SAK' == journalpost.sak.sakstype)) &&
                (this.selectedThemeCode == null || this.selectedThemeCode === journalpost.tema) &&
                this.selectedJornalpostTypes.includes(journalpost.journalposttype)
        );
    }

    /**
     * Add error messages to the error message list.
     */
    setErrorMessage(err) {
        this.setErrorMessage(err, '');
    }

    setErrorMessage(err, type) {
        type = err.body && type === 'caughtError' ? 'fetchResponseError' : type;
        switch (type) {
            case 'fetchResponseError':
                if (Array.isArray(err.body)) {
                    this.errors = this.errors.concat(err.body.map((e) => e.message));
                } else if (typeof err.body.message === 'string') {
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
