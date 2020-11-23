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
    @api recordId;
    @api selectedJornalpostTypes;
    @api selectedTema;
    @api nmbOfJournalposts;

    @api field;
    @api objectApiName;
    @api relationField;
    @api parentRelationField;
    @api parentObjectApiName;
    @api brukerIdType;

    // tracked resources
    @track journalposts;
    @track filteredJournalPosts;
    @track error;

    @track availableThemes = [];
    @track availableProcessThemes = [];

    isLoaded;
    isLoadingMore;

    //Account data that can be used
    wiredAccount;
    account;

    //Query variables
    queryVariables = {
        brukerId: {},
        foerste: 10
    }

    connectedCallback() {
        //Set default variables
        this.isLoadingMore = false;
        this.isLoaded = false;
        this.nmbOfJournalposts = (this.nmbOfJournalposts) ? this.nmbOfJournalposts : DEFAULT_NMB_JOURNALPOSTS;
        this.selectedTema = (this.selectedTema) ? this.selectedTema : DEFAULT_SELECTED_TEMA;
        this.selectedJornalpostTypes = (this.selectedJornalpostTypes) ? this.selectedJornalpostTypes : DEFAULT_SELECTED_JOURNALPOST_TYPES;
        this.journalposts = [];
        this.filteredJournalPosts = [];

        this.queryVariables.foerste = this.nmbOfJournalposts;

        this.getAccountQueryVariables();
        this.callGetJournalpostsUser();
    }

    async getAccountQueryVariables() {
        const inputParams = {
            field: this.field,
            parentId: this.recordId,
            objectApiName: this.objectApiName,
            relationField: this.relationField,
            parentRelationField: this.parentRelationField,
            parentObjectApiName: this.parentObjectApiName,
            brukerIdType: this.brukerIdType
        };
        try {
            this.queryVariables.brukerId = await getAccountQueryVariables(inputParams);
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
        // Apex can't handle inner classes.
        // We need to stringify and parse on the other side.
        const inputParams = {
            queryVariablesString: JSON.stringify(this.queryVariables),
            queryFieldString: JSON.stringify(QUERY_FIELDS)
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

    setErrorMessage(error, type) {
        let errorString;

        switch (type) {
            case 'fetchResponseError':
                if (Array.isArray(error.body)) {
                    errorString = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    errorString = error.body.message;
                }
                break;
            case 'journalpostError':
                errorString = '';
                if (error.status) {
                    errorString = error.status + ' ';
                }
                errorString += error.error + ' - ' + error.message;
                break;
            case 'caughtError':
                errorString = 'Ukjent feil: ' + error.message;
                break;
            default:
                errorString = 'Ukjent feil ' + err;

        }

        this.error = errorString;
    }
}