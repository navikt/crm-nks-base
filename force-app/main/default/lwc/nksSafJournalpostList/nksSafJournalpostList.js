import { LightningElement, api, track } from 'lwc';
import getJournalPosts from '@salesforce/apex/NKS_SafJournalpostListController.getJournalPosts';

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
            queryFields: [{ name: 'fagsakId' }]
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
                        { name: 'saksbehandlerHarTilgang' },
                        { name: 'skjerming' }
                    ]
                }
            ]
        }
    ]
};

export default class NksSafJournalpostList extends LightningElement {
    @api recordId; // Id from record page (From UiRecordAPI)
    @api objectApiName; // Value from UiRecordAPI

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
    selectedCase = null;

    //Query variables
    queryVariables = {
        brukerId: {},
        tema: null,
        journalstatuser: ['JOURNALFOERT', 'FERDIGSTILT', 'EKSPEDERT'],
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

    get hasErrors() {
        return 1 <= this.errors.length ? true : false;
    }
    get canLoadMore() {
        return this.sideInfo ? this.sideInfo.finnesNesteSide : false;
    }

    getHasJournalposttype(statusElement) {
        return this._selectedJornalpostTypes.includes(statusElement);
    }

    setJournalpostTypeCheckBoxes() {
        Array.from(this.template.querySelectorAll('lightning-input.journalpostType')).forEach(
            (element) => {
                this.getJournalposttype(element.name);
            }
        );
    }

    setJournalposttype(value, statusElement) {
        if (value !== this.getJournalposttype(statusElement)) {
            let statuses = this._selectedJornalpostTypes.filter(
                (element) => element !== statusElement
            );

            if (value === true) {
                statuses = statuses.push(statusElement);
            }

            this._selectedJornalpostTypes = statuses;
        }
    }

    set selectedTema(value) {
        if (value === 'all') {
            this.queryVariables.tema = null;
        } else if (Array.isArray(value)) {
            this.queryVariables.tema = [value];
        } else {
            this.queryVariables.tema = value;
        }
    }

    /**
     * Get the last journalpostId in the journalpost list and add this to the query variables
     */
    queryMoreJournalPosts() {
        this.callGetJournalPosts(true);
    }

    async callGetJournalPosts(isQueryMore) {
        isQueryMore = this.canLoadMore ? isQueryMore : false;
        this.queryVariables.etter = isQueryMore ? this.sideInfo.sluttpeker : null; // this.journalposts[this.journalposts.length - 1].journalpostId : null;
        this.isLoadingMore = isQueryMore;

        const inputParams = {
            brukerIdField: this.brukerIdField,
            objectApiName: this.viewedObjectApiName,
            relationshipField: this.relationshipField,
            viewedRecordId: this.viewedRecordId,
            queryVariables: this.queryVariables,
            queryField: QUERY_FIELDS
        };

        this.error = null;

        try {
            const journalpostData = await getJournalPosts(inputParams);
            this.sideInfo = journalpostData.documentOverview.sideInfo;
            this.journalposts = isQueryMore
                ? this.journalposts.concat(journalpostData.documentOverview.journalposter)
                : journalpostData.documentOverview.journalposter;
            this.filterAllJournalposts();
        } catch (err) {
            this.setErrorMessage(err, 'caughtError');
        }

        this.isLoaded = true;
        this.isLoadingMore = false;
    }

    handleJournalpostTypeCheckboxChange() {
        const elements = Array.from(
            this.template.querySelectorAll('lightning-input.journalpostType')
        );

        let checked = elements.filter((element) => element.checked).map((element) => element.name);
        this._selectedJornalpostTypes = checked;
        this.filterAllJournalposts();
    }

    handleAvailableThemes(event) {
        this.queryVariables.tema = event.detail;
        this.callGetJournalPosts(false);
    }

    handleSelectCase(event) {
        this.selectedCase = event.detail;
        this.filterAllJournalposts();
    }

    /**
     * Set filteredJournalPosts to all journals where tema is matching the selected temas (or temalist is empty == alle tema) AND the journalpost type is matching
     */
    filterAllJournalposts() {
        this.filteredJournalPosts = this.journalposts.filter(
            (journalpost) =>
                (this.selectedCase == null || this.selectedCase === journalpost.sak.fagsakId) &&
                this.selectedJornalpostTypes.includes(journalpost.journalposttype)
        );
    }

    /**
     * Add error messages to the error message list.
     */
    setErrorMessage(error) {
        this.setErrorMessage(error, '');
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
