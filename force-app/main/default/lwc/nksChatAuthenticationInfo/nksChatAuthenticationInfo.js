import { LightningElement, api, wire, track } from 'lwc';
import { subscribe, unsubscribe } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getChatInfo from '@salesforce/apex/ChatAuthController.getChatInfo';
import setStatusRequested from '@salesforce/apex/ChatAuthController.setStatusRequested';
import getCommunityAuthUrl from '@salesforce/apex/ChatAuthController.getCommunityAuthUrl';

//#### LABEL IMPORTS ####
import AUTH_REQUESTED from '@salesforce/label/c.CRM_Chat_Authentication_Requested';
import AUTH_STARTED from '@salesforce/label/c.CRM_Chat_Authentication_Started';
import IDENTITY_CONFIRMED from '@salesforce/label/c.CRM_Chat_Identity_Confirmed';
import UNCONFIRMED_IDENTITY_WARNING from '@salesforce/label/c.CRM_Chat_Unconfirmed_Identity_Warning';
import IDENTITY_CONFIRMED_DISCLAIMER from '@salesforce/label/c.CRM_Chat_Identity_Confirmed_Disclaimer';
import AUTH_INIT_FAILED from '@salesforce/label/c.CRM_Chat_Authentication_Init_Failed';
import CHAT_LOGIN_MSG_NO from '@salesforce/label/c.NKS_Chat_Login_Message_NO';
import CHAT_LOGIN_MSG_EN from '@salesforce/label/c.NKS_Chat_Login_Message_EN';

export default class ChatAuthenticationOverview extends LightningElement {
    labels = {
        AUTH_REQUESTED,
        AUTH_STARTED,
        IDENTITY_CONFIRMED,
        UNCONFIRMED_IDENTITY_WARNING,
        IDENTITY_CONFIRMED_DISCLAIMER,
        AUTH_INIT_FAILED
    };
    @api loggingEnabled; //Determines if console logging is enabled for the component
    @api recordId;
    @api objectApiName;
    @api accountFields; //Comma separated string with field names to display from the related account
    @api caseFields; //Comma separated string with field names to display from the related case
    @api personFields; //Comma separated string with field names to display from the related accounts person
    accountId; //Transcript AccountId
    caseId; //Transcript CaseId
    personId; //Transcript Account PersonId
    currentAuthenticationStatus; //Current auth status of the chat transcript
    sendingAuthRequest = false; //Switch used to show spinner when initiatiing auth process
    activeConversation; //Boolean to determine if the componenet is rendered in a context on an active chat conversation
    chatLanguage;
    chatAuthUrl;
    subscription = {}; //Unique empAPI subscription for the component instance

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
        return (
            this.currentAuthenticationStatus === 'In Progress' ||
            this.currentAuthenticationStatus === 'Completed'
        );
    }

    get authenticationComplete() {
        return this.currentAuthenticationStatus == 'Completed';
    }

    get isEmpSubscribed() {
        return (
            Object.keys(this.subscription).length !== 0 &&
            this.subscription.constructor === Object
        );
    }

    //#### /GETTERS ###

    connectedCallback() {
        this.getAuthUrl();
    }

    @wire(getChatInfo, { chatTranscriptId: '$recordId' })
    wiredStatus({ error, data }) {
        if (data) {
            this.log(data);
            this.currentAuthenticationStatus = data.AUTH_STATUS;
            this.activeConversation = data.CONVERSATION_STATUS === 'InProgress';
            this.accountId = data.ACCOUNTID;
            this.caseId = data.CASEID;
            this.personId = data.PERSONID;
            this.chatLanguage = data.CHAT_LANGUAGE;
        } else {
            this.currentAuthenticationStatus = 'Not Started';
            this.log(error);
        }
        //If the authentication is not completed, subscribe to the push topic to receive events
        if (
            this.currentAuthenticationStatus !== 'Completed' &&
            !this.isLoading &&
            !this.isEmpSubscribed
        ) {
            this.handleSubscribe();
        }
    }

    //Calls apex to get the correct community url for the given sandbox
    getAuthUrl() {
        getCommunityAuthUrl({})
            .then((url) => {
                this.chatAuthUrl = url;
            })
            .catch((error) => {
                console.log(
                    'Failed to retrieve auth url: ' +
                        JSON.stringify(error, null, 2)
                );
            });
    }

    //Handles subscription to streaming API for listening to changes to auth status
    handleSubscribe() {
        let _this = this;
        // Callback invoked whenever a new event message is received
        const messageCallback = function (response) {
            console.log('AUTH STATUS UPDATED');
            //Only overwrite status if the event received belongs to this record
            _this.currentAuthenticationStatus =
                response.data.sobject.Id === _this.recordId
                    ? response.data.sobject.CRM_Authentication_Status__c
                    : _this.currentAuthenticationStatus;
            //If authentication now is complete, get the account id
            if (_this.authenticationComplete) {
                _this.accountId =
                    response.data.sobject.Id === _this.recordId
                        ? response.data.sobject.AccountId
                        : null;
                _this.sendLoginEvent();
                _this.handleUnsubscribe();
            }
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        //Removed subscription to record specific channel as there are issues when loading multiple components and subscribing
        //to record specific channels on initialization. New solution verifies Id in messageCallback
        subscribe(
            '/topic/Chat_Auth_Status_Changed' /*?Id=" + this.recordId*/,
            -1,
            messageCallback
        ).then((response) => {
            // Response contains the subscription information on successful subscribe call
            this.subscription = response;
            console.log(
                'Successfully subscribed to : ',
                JSON.stringify(response.channel)
            );
        });
    }

    handleUnsubscribe() {
        // Invoke unsubscribe method to not receive duplicate messages for this context
        unsubscribe(this.subscription, (response) => {
            console.log('Unsubscribed: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        })
            .then((success) => {
                //Successfull unsubscribe
                this.log('Successful unsubscribe');
            })
            .catch((error) => {
                console.log(
                    'EMP unsubscribe failed: ' + JSON.stringify(error, null, 2)
                );
            });
    }

    sendLoginEvent() {
        //Message defaults to norwegian
        const loginMessage =
            this.chatLanguage === 'en_US'
                ? CHAT_LOGIN_MSG_EN
                : CHAT_LOGIN_MSG_NO;

        //Sending event handled by parent to to trigger default chat login message
        const authenticationCompleteEvt = new CustomEvent(
            'authenticationcomplete',
            {
                detail: { loginMessage }
            }
        );
        this.dispatchEvent(authenticationCompleteEvt);
    }

    //Sends event handled by parent to utilize conversation API to send message for init of auth process
    requestAuthentication() {
        this.sendingAuthRequest = true;
        const authUrl = this.chatAuthUrl;

        //Pass the chat auth url
        const requestAuthenticationEvent = new CustomEvent(
            'requestauthentication',
            {
                detail: { authUrl }
            }
        );
        this.dispatchEvent(requestAuthenticationEvent);
    }

    //Call from aura parent after a successful message to init auth process
    setAuthStatusRequested() {
        setStatusRequested({ chatTranscriptId: this.recordId })
            .then((result) => {
                this.log('Successful update');
            })
            .catch((error) => {
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
        } else {
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
