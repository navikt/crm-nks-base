import { LightningElement, api, wire } from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import getChatStatus from '@salesforce/apex/ChatAuthController.getChatStatus';
import setStatusRequested from '@salesforce/apex/ChatAuthController.setStatusRequested';

//#### LABEL IMPORTS ####
import AUTH_REQUESTED from '@salesforce/label/c.CRM_Chat_Authentication_Requested';
import AUTH_STARTED from '@salesforce/label/c.CRM_Chat_Authentication_Started';
import IDENTITY_CONFIRMED from '@salesforce/label/c.CRM_Chat_Identity_Confirmed';
import UNCONFIRMED_IDENTITY_WARNING from '@salesforce/label/c.CRM_Chat_Unconfirmed_Identity_Warning';
import IDENTITY_CONFIRMED_DISCLAIMER from '@salesforce/label/c.CRM_Chat_Identity_Confirmed_Disclaimer';
import AUTH_INIT_FAILED from '@salesforce/label/c.CRM_Chat_Authentication_Init_Failed';

export default class ChatAuthenticationOverview extends LightningElement {

    labels = {
        AUTH_REQUESTED,
        AUTH_STARTED,
        IDENTITY_CONFIRMED,
        UNCONFIRMED_IDENTITY_WARNING,
        IDENTITY_CONFIRMED_DISCLAIMER,
        AUTH_INIT_FAILED
    }
    currentAuthenticationStatus;       //Current auth status of the chat transcript
    sendingAuthRequest = false;        //Switch used to show spinner when initiatiing auth process
    activeConversation;                 //Boolean to determine if the componenet is rendered in a context on an active chat conversation
    @api loggingEnabled;                //Determines if console logging is enabled for the component
    @api recordId;

    //#### GETTERS ####

    get isLoading() {
        return this.currentAuthenticationStatus ? false : true;
    }

    get cannotInitAuth() {
        return !(this.activeConversation && !this.sendingAuthRequest);
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

    @wire(getChatStatus, { chatTranscriptId: '$recordId' })
    wiredStatus({ error, data }) {
        if (data) {
            this.log(data);
            this.currentAuthenticationStatus = data.AUTH_STATUS;
            this.activeConversation = data.CONVERSATION_STATUS === 'InProgress';
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
            //Only overwrite status if the event received belongs to this record
            _this.currentAuthenticationStatus = response.data.sobject.Id === _this.recordId ? response.data.sobject.CRM_Authentication_Status__c : _this.currentAuthenticationStatus;

            //If authentication now is complete we as the aura container to refresh the view
            if (_this.authenticationComplete) {
                const refreshViewEvent = new CustomEvent('refreshview');
                _this.dispatchEvent(refreshViewEvent);
            }
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        //Removed subscription to record specific channel as there are issues when loading multiple components and subscribing
        //to record specific channels on initialization. New solution verifies Id in messageCallback
        subscribe("/topic/Chat_Auth_Status_Changed" /*?Id=" + this.recordId*/, -1, messageCallback).then(response => {
            // Response contains the subscription information on successful subscribe call
            console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
        });
    }

    //Sends event handled by parent to utilize conversation API to send message for init of auth process
    requestAuthentication() {
        this.sendingAuthRequest = true;

        const requestAuthenticationEvent = new CustomEvent('requestauthentication');
        this.dispatchEvent(requestAuthenticationEvent);
    }

    //Call from aura parent after a successful message to init auth process
    setAuthStatusRequested() {

        setStatusRequested({ chatTranscriptId: this.recordId })
            .then(result => {
                this.log('Successfull update');
            })
            .catch(error => {
                this.log(error);
            })
            .finally(() => {
                this.sendingAuthRequest = false;
            });
    }

    @api
    authRequestHandling(success) {
        if (success) {
            this.setAuthStatusRequested();
        }
        else {
            this.showAuthError();
        }
    }

    //Displays an error toast message if there was any issue in initialiizing authentication
    showAuthError() {
        const event = new ShowToastEvent({
            title: 'Authentication error',
            message: AUTH_INIT_FAILED,
            variant: 'error',
            mode: 'sticky'
        });
        this.dispatchEvent(event);
    }

    //Logger function
    log(loggable) {
        if (this.loggingEnabled) console.log(loggable);
    }
}