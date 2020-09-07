import { LightningElement, api, wire } from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import getAuthStatus from '@salesforce/apex/ChatAuthController.getAuthStatus';
import setStatusRequested from '@salesforce/apex/ChatAuthController.setStatusRequested';

//#### LABEL IMPORTS ####
import AUTH_REQUESTED from '@salesforce/label/c.CRM_Chat_Authentication_Requested';
import AUTH_STARTED from '@salesforce/label/c.CRM_Chat_Authentication_Started';
import IDENTITY_CONFIRMED from '@salesforce/label/c.CRM_Chat_Identity_Confirmed';
import UNCONFIRMED_IDENTITY_WARNING from '@salesforce/label/c.CRM_Chat_Unconfirmed_Identity_Warning';
import IDENTITY_CONFIRMED_DISCLAIMER from '@salesforce/label/c.CRM_Chat_Identity_Confirmed_Disclaimer';

export default class ChatAuthenticationOverview extends LightningElement {

    labels = {
        AUTH_REQUESTED,
        AUTH_STARTED,
        IDENTITY_CONFIRMED,
        UNCONFIRMED_IDENTITY_WARNING,
        IDENTITY_CONFIRMED_DISCLAIMER
    }
    currentAuthenticationStatus;
    //Determines if console logging is enabled for the component
    sendingAuthRequest = false;
    @api loggingEnabled
    @api recordId;

    //#### GETTERS ####

    get isLoading() {
        return this.currentAuthenticationStatus ? false : true;
    }

    get authenticationRequested() {
        return this.currentAuthenticationStatus !== 'Not Started';
    }

    get authenticationStarted() {
        return (this.currentAuthenticationStatus === 'In Progress' || this.currentAuthenticationStatus === 'Completed');
    }

    get authenticationComplete() {
        return this.currentAuthenticationStatus == 'Completed';
    }

    //#### /GETTERS ###

    connectedCallback() {
        this.handleSubscribe();
    }

    @wire(getAuthStatus, { chatTranscriptId: '$recordId' })
    wiredStatus({ error, data }) {
        if (data) {
            this.log(data);
            this.currentAuthenticationStatus = data;
        } else {
            this.currentAuthenticationStatus = 'Not Started'
            this.log(error);
        }
    }

    //Handles subscription to streaming API for listening to changes to auth status
    handleSubscribe() {
        let _this = this;
        // Callback invoked whenever a new event message is received
        const messageCallback = function (response) {
            console.log('AUTH STATUS UPDATED');
            _this.currentAuthenticationStatus = response.data.sobject.CRM_Authentication_Status__c;

            //If authentication now is complete we as the aura container to refresh the view
            if (_this.authenticationComplete) {
                const refreshViewEvent = new CustomEvent('refreshview');
                _this.dispatchEvent(refreshViewEvent);
            }
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe("/topic/Chat_Auth_Status_Changed?Id=" + this.recordId, -1, messageCallback).then(response => {
            // Response contains the subscription information on successful subscribe call
            console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
        });
    }

    //Handles initiation of the authentication process for the chat visitor
    handleRequest() {
        this.sendingAuthRequest = true;

        setStatusRequested({ chatTranscriptId: this.recordId })
            .then(result => {
                this.log('Successfull update');
                const requestAuthenticationEvent = new CustomEvent('requestauthentication');
                this.dispatchEvent(requestAuthenticationEvent);
            })
            .catch(error => {
                this.log(error);
            })
            .finally(() => {
                this.sendingAuthRequest = false;
            });
    }

    //Logger function
    log(loggable) {
        if (this.loggingEnabled) console.log(loggable);
    }
}