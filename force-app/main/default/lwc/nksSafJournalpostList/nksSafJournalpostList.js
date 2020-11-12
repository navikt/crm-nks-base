import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_INT_PERSONIDENT from '@salesforce/schema/Account.INT_PersonIdent__c';
import ACCOUNT_INT_ORGANIZATION_NUMBER from '@salesforce/schema/Account.INT_OrganizationNumber__c';
import ACCOUNT_IS_PERSON_ACCOUNT from '@salesforce/schema/Account.IsPersonAccount';
import getJournalpostsUser from "@salesforce/apex/NKS_SafJournalpostListController.getJournalpostsUser";

const ACCOUNT_FIELDS = [ACCOUNT_INT_PERSONIDENT, ACCOUNT_INT_ORGANIZATION_NUMBER, ACCOUNT_IS_PERSON_ACCOUNT];
const DEFAULT_NMB_JOURNALPOSTS = 10;
const DEFAULT_SELECTED_JOURNALPOST_TYPES = ["I", "U", "N"];
const DEFAULT_SELECTED_TEMAS = [];
const QUERY_FIELDS = {
    name: "journalposter",
    queryFields: [
        { name: "journalpostId" },
        { name: "tittel" },
        { name: "journalposttype" },
        { name: "journalstatus" },
        { name: "tema" },
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
    @api selectedTemas;
    @api nmbOfJournalposts;

    // tracked resources
    @track journalposts;
    @track filteredJournalPosts;
    @track error;

    // @track queryFields;
    isLoaded;
    isLoadingMore;

    //Account data that can be used
    wiredAccount;
    account;

    //Query variables
    queryVariables = {
        brukerId: {
            id: "",
            type: "",
        },
        foerste: 10
    }

    connectedCallback() {
        //Set default variables
        this.isLoadingMore = false;
        this.isLoaded = false;
        this.nmbOfJournalposts = (this.nmbOfJournalposts) ? nmbOfJournalposts : DEFAULT_NMB_JOURNALPOSTS;
        // this.queryFields = (this.queryFields) ? this.queryFields : DEFAULT_QUERY_FIELDS;
        this.selectedTemas = (this.selectedTemas) ? this.selectedTemas : DEFAULT_SELECTED_TEMAS;
        this.selectedJornalpostTypes = (this.selectedJornalpostTypes) ? this.selectedJornalpostTypes : DEFAULT_SELECTED_JOURNALPOST_TYPES;
        this.journalposts = [];
        this.filteredJournalPosts = [];

        this.queryVariables.foerste = this.nmbOfJournalposts;
    }

    /**
     * Get the data we need from the account
     * @param {*} value 
     */
    @wire(getRecord, { recordId: "$recordId", fields: ACCOUNT_FIELDS })
    getWiredAccount(value) {
        this.wiredAccount = value;
        const { data, error } = value;

        if (data) {
            this.journalposts = [];
            this.filteredJournalPosts = [];
            this.account = data;
            this.setQueryVariablesFromAccount();
            this.callGetJournalpostsUser();
        }
        else if (error) {
            this.setErrorMessage(error, 'fetchResponseError');
            this.isLoaded = true;
        }
    }

    /**
     * Set the queryVariables on the BrukerId based on the account
     */
    setQueryVariablesFromAccount() {
        if (this.account.fields.IsPersonAccount.value) {
            this.queryVariables.brukerId.id = this.account.fields.INT_PersonIdent__c.value;
            this.queryVariables.brukerId.type = 'AKTOERID';
        } else {
            this.queryVariables.brukerId.id = this.account.fields.INT_OrganizationNumber__c.value;
            this.queryVariables.brukerId.type = 'ORGNR';
        }
    }

    /**
     * Get the last journalpostId in the journalpost list and add this to the query variables
     */
    queryMoreJournalPosts() {
        this.isLoadingMore = true;
        let lastJournalpostId = this.journalposts[this.journalposts.length - 1].journalpostId;
        this.queryVariables.etter = lastJournalpostId;
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

    /**
     * Set filteredJournalPosts to all journals where tema is matching the selected temas (or temalist is empty == alle tema) AND the journalpost type is matching
     */
    filterAllJournalposts() {
        this.filteredJournalPosts = this.journalposts.filter(journalpost => (
            this.selectedTemas.length > 1 || this.selectedTemas.includes(journalpost.tema))
            &&
            (this.selectedJornalpostTypes.includes(journalpost.selectedJornalpostTypes)
            ));
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