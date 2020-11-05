import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_INT_PERSONIDENT from '@salesforce/schema/Account.INT_PersonIdent__c';
import getJournalposts from "@salesforce/apex/NKS_SafJournalpostListController.getJournalposts";

export default class NksSafJournalpostList extends LightningElement {
    @api recordId;

    // tracked resources
    @track journalposts;
    @track documentOverview;
    @track error;

    //Account data that can be used
    wiredAccount;
    account;

    //account parameters used to get journal posts
    userId;
    userType;

    isLoaded = false;

    /**
     * Get the data we need from the account
     * TODO: Add logic for errorhandling
     * TODO: Add logic for different account types/ids: orgNmb, ssn or aktorId
     * @param {*} value 
     */
    @wire(getRecord, { recordId: "$recordId", fields: [ACCOUNT_INT_PERSONIDENT] })
    getWiredAccount(value) {
        this.wiredAccount = value;
        const { data, error } = value;

        if (data) {
            this.account = data;
            this.userId = this.account.fields.INT_PersonIdent__c.value;
            this.userType = 'AKTOERID';
        }
        else if (error) {
            //Do something
        }
    }

    /**
     * Get the journal posts related to the account
     * TODO: Add logic for error handling
     * @param {*} value 
     */
    @wire(getJournalposts, { userId: '$userId', userType: '$userType' })
    wiredDocumentOverview(value) {
        const { data, error } = value;

        if (data) {
            this.journalposts = [];
            this.error = data.error;
            this.documentOverview = data.documentOverview;

            if (true === data.isSuccess) {
                this.journalposts = this.documentOverview.journalposter;
            }
            this.isLoaded = true;
        }

        if (error) {
            this.isLoaded = true;
        }
    }

    /**
     * Get the error message that we want to display
     * TODO: Add logic
     */
    get errorMessage() {
        if (error) {
            if (401 === error.status) {

            }
            else {
                return error.message;
            }
        }
    }
}