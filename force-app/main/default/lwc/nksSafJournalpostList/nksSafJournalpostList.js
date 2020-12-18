import { LightningElement, api, track } from 'lwc';
import getJournalpostsUser from "@salesforce/apex/NKS_SafJournalpostListController.getJournalpostsUser";
import getAccountQueryVariables from "@salesforce/apex/NKS_SafJournalpostListController.getAccountQueryVariables";

const DEFAULT_NMB_JOURNALPOSTS = 10;
const DEFAULT_SELECTED_JOURNALPOST_TYPES = ["I", "U", "N"];
const DEFAULT_SELECTED_TEMA = 'all';
const QUERY_FIELDS = {
    name: "journalposter",
    queryFields: [
        { name: "journalpostId" },
        { name: "tittel" },
        { name: "journalposttype" },
        { name: "journalstatus" },
        { name: "tema" },
        { name: "temanavn" },
        { name: "behandlingstema" },
        { name: "behandlingstemanavn" },
        { name: "datoOpprettet" },
        {
            name: "sak",
            queryFields: [
                { name: "fagsakId" }
            ]
        },
        {
            name: "avsenderMottaker",
            queryFields: [
                { name: "navn" }
            ]
        },
        {
            name: "dokumenter",
            queryFields: [
                { name: "dokumentInfoId" },
                { name: "tittel" },
                {
                    name: "dokumentvarianter",
                    queryFields: [
                        { name: "variantformat" },
                        { name: "filnavn" },
                        { name: "saksbehandlerHarTilgang" },
                        { name: "skjerming" },
                    ]
                }
            ]
        }
    ]
};

export default class NksSafJournalpostList extends LightningElement {
    @api selectedJornalpostTypes;   //The selected Journalpost types to show
    @api selectedTema;              //The selected Tema to show
    @api recordId;                  // Id from record page (From UiRecordAPI)
    @api objectApiName;             // Value from UiRecordAPI
    @api viewedRecordId;            // Id of the record to display information for
    @api viewedObjectApiName = null // API name of the object to display information from
    @api relationshipField = null;  // Field api name if the recordId is to be set via relationship
    @api brukerIdField;             //Field pointing to the user id
    @api brukerIdType;              //The user Id type to use

    // tracked resources
    @track journalposts = [];
    @track filteredJournalPosts = [];
    @track errors = [];
    @track availableThemes = [];
    @track availableProcessThemes = [];

    isLoaded = false;
    isLoadingMore = false;

    //Account data that can be used
    wiredAccount;
    account;

    _nmbOfJournalposts;

    //Query variables
    queryVariables = {
        brukerId: {},
        foerste: 10
    }

    set nmbOfJournalPosts(value) {
        this._nmbOfJournalposts = value ? value : DEFAULT_NMB_JOURNALPOSTS;
        this.queryVariables.foerste = this.nmbOfJournalPosts;
    }

    @api get nmbOfJournalPosts() {
        return this._nmbOfJournalposts;
    }

    get hasErrors() {
        return 1 <= this.errors.length ? true : false;
    }

    connectedCallback() {
        this.viewedObjectApiName = this.viewedObjectApiName == null ? this.objectApiName : this.viewedObjectApiName;
        this.viewedRecordId = this.viewedRecordId ? this.viewedRecordId : this.recordId;
        this.selectedTema = (this.selectedTema) ? this.selectedTema : DEFAULT_SELECTED_TEMA;
        this.selectedJornalpostTypes = (this.selectedJornalpostTypes) ? this.selectedJornalpostTypes : DEFAULT_SELECTED_JOURNALPOST_TYPES;

        this.getAccountQueryVariables();
    }

    async getAccountQueryVariables() {
        const inputParams = {
            brukerIdField: this.brukerIdField,
            objectApiName: this.viewedObjectApiName,
            relationshipField: this.relationshipField,
            viewedRecordId: this.viewedRecordId,
            brukerIdType: this.brukerIdType
        };

        try {
            this.queryVariables.brukerId = await getAccountQueryVariables(inputParams);
            this.callGetJournalpostsUser();
        } catch (err) {
            this.setErrorMessage(err, 'caughtError');
        }
    }

    /**
     * Get the last journalpostId in the journalpost list and add this to the query variables
     */
    queryMoreJournalPosts() {
        let lastJournalpostId = this.journalposts[this.journalposts.length - 1].journalpostId;

        this.queryVariables.etter = lastJournalpostId;
        this.isLoadingMore = true;

        this.callGetJournalpostsUser();
    }

    /**
     * Call getJournalpostsUser apex method and add the new journalposts to the journalpost list
     */
    async callGetJournalpostsUser() {

        const inputParams = {
            queryVariables: this.queryVariables,
            queryField: QUERY_FIELDS
        };

        this.error = null;

        try {
            const journalpostData = await getJournalpostsUser(inputParams);

            if (true === journalpostData.isSuccess) {
                this.journalposts = this.journalposts.concat(journalpostData.documentOverview.journalposter);
                this.collectThemes();
                this.filterAllJournalposts();
            } else {
                this.setErrorMessage(journalpostData.error, 'journalpostError');
            }

        } catch (err) {
            this.setErrorMessage(err, 'caughtError');
        }

        this.isLoaded = true;
        this.isLoadingMore = false;
    }

    setSelectedTheme(event) {
        this.selectedTema = event.detail;
        this.filterAllJournalposts();
    }

    collectThemes() {
        let processThemes = [];
        let themes = [];

        this.journalposts.forEach(journalpost => {

            if (false == themes.some(t => journalpost.tema === t.value)) {
                let theme = this.setTheme(journalpost.tema, journalpost.temaNavn);
                if (theme) { themes.push(theme); }
            }

            if (false == processThemes.some(t => journalpost.behandlingstema === t.value)) {
                let processTheme = this.setTheme(journalpost.behandlingstema, journalpost.behandlingstemanavn);
                if (processTheme) { processThemes.push(processTheme); }
            }
        });

        this.availableThemes = themes;
        this.availableProcessThemes = processThemes;
    }

    setTheme(code, name) {
        if (code && name) {
            return { value: code, label: name };
        }

        return null;
    }

    /**
     * Set filteredJournalPosts to all journals where tema is matching the selected temas (or temalist is empty == alle tema) AND the journalpost type is matching
     */
    filterAllJournalposts() {
        this.filteredJournalPosts = this.journalposts.filter(journalpost => (
            this.selectedTema === 'all' || this.selectedTema === journalpost.tema)
            &&
            (this.selectedJornalpostTypes.includes(journalpost.journalposttype)
            ));
        console.log(this.filteredJournalPosts);
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
                    this.errors = this.errors.concat(error.body.map(e => e.message));
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