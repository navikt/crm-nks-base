import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { isEmpEnabled, onError, subscribe, unsubscribe } from 'lightning/empApi';
import getCallAuthenticationStatus from '@salesforce/apex/NKS_CallFlowController.getCallAuthenticationStatus';
import ACCOUNT_FIELD from '@salesforce/schema/Case.AccountId';
import ORIGIN_FIELD from '@salesforce/schema/Case.Origin';
import SESSION_FIELD from '@salesforce/schema/Case.NKS_Puzzel_Session_Id__c';

const CASE_FIELDS = [ACCOUNT_FIELD, ORIGIN_FIELD, SESSION_FIELD];
const CHANNEL = '/event/NKS_Call_Authentication_Changed__e';
const streamingErrorListeners = new Set();
let streamingErrorHandlerRegistered = false;

export default class NksCallAuthenticationBadge extends LightningElement {
    isAuthenticated = false;
    _recordId;
    _initialAccountId;
    _caseContext;
    _requestVersion = 0;
    _canCheck = false;
    _hasLookupError = false;
    _hasStreamingError = false;
    _sessionId;
    _subscription;
    _connectionVersion = 0;
    _subscriptionPending = false;
    _lookupVersion;
    _refreshQueued = false;
    _streamingErrorListener;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        if (value !== this._recordId) {
            this.resetAuthentication();
            this.clearSubscription();
            this._caseContext = null;
            this._canCheck = false;
            this._sessionId = null;
            this._initialAccountId = undefined;
            this._recordId = value;
        }
    }

    connectedCallback() {
        this._streamingErrorListener = (error) => {
            const failedChannel = error?.subscription || error?.channel;
            if (
                this._canCheck &&
                (failedChannel === CHANNEL ||
                    error?.channel === '/meta/connect' ||
                    error?.channel === '/meta/handshake')
            ) {
                this.showStreamingError(error);
            }
        };
        streamingErrorListeners.add(this._streamingErrorListener);
        if (!streamingErrorHandlerRegistered) {
            onError((error) => streamingErrorListeners.forEach((listener) => listener(error)));
            streamingErrorHandlerRegistered = true;
        }
        this.startListening();
        if (this._canCheck) {
            this.checkAuthentication(this._requestVersion);
        }
    }

    disconnectedCallback() {
        this.resetAuthentication();
        this.clearSubscription();
        streamingErrorListeners.delete(this._streamingErrorListener);
    }

    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
    wiredCase({ data, error }) {
        if (error) {
            this.resetAuthentication();
            this._caseContext = null;
            this._canCheck = false;
            this.clearSubscription();
            this.showError(error, 'Last inn saken på nytt for å prøve igjen.');
        } else if (data && data.id === this.recordId) {
            const accountId = data.fields.AccountId.value;
            const sessionId = data.fields.NKS_Puzzel_Session_Id__c.value;
            const origin = data.fields.Origin.value;
            if (this._initialAccountId === undefined && accountId) {
                this._initialAccountId = accountId;
            }
            const context = JSON.stringify([data.id, accountId, sessionId, origin]);
            if (context === this._caseContext) {
                return;
            }
            this.resetAuthentication();
            this._caseContext = context;
            this._sessionId = sessionId;
            this._canCheck = Boolean(
                origin === 'Phone' && accountId && accountId === this._initialAccountId && sessionId
            );
            if (this._canCheck) {
                this.startListening();
                this.checkAuthentication(this._requestVersion);
            } else {
                this.clearSubscription();
            }
        }
    }

    async checkAuthentication(requestVersion) {
        if (!this.isConnected || !this._canCheck || requestVersion !== this._requestVersion) {
            return;
        }
        if (this._lookupVersion === requestVersion) {
            this._refreshQueued = true;
            return;
        }
        this._lookupVersion = requestVersion;
        try {
            const result = await getCallAuthenticationStatus({ caseId: this.recordId });
            if (!this.isConnected || requestVersion !== this._requestVersion) {
                return;
            }
            this._hasLookupError = false;
            this.isAuthenticated = result.isAuthenticated === true;
        } catch (error) {
            if (this.isConnected && requestVersion === this._requestVersion) {
                this.isAuthenticated = false;
                if (!this._hasLookupError) {
                    this.showError(error);
                    this._hasLookupError = true;
                }
            }
        } finally {
            if (requestVersion === this._requestVersion) {
                this._lookupVersion = null;
                if (this._refreshQueued) {
                    this._refreshQueued = false;
                    this.checkAuthentication(requestVersion);
                }
            }
        }
    }

    async startListening() {
        if (this._subscription || this._subscriptionPending || !this.isConnected || !this._canCheck) {
            return;
        }
        const connectionVersion = ++this._connectionVersion;
        this._subscriptionPending = true;
        try {
            if (!(await isEmpEnabled())) {
                throw new Error('Streaming is not supported in this browser context.');
            }
            if (!this.isConnected || connectionVersion !== this._connectionVersion) {
                return;
            }
            const subscription = await subscribe(CHANNEL, -1, (message) => {
                if (
                    this.isConnected &&
                    connectionVersion === this._connectionVersion &&
                    message.data?.payload?.SessionId__c === this._sessionId
                ) {
                    this._hasStreamingError = false;
                    this.checkAuthentication(this._requestVersion);
                }
            });
            if (!this.isConnected || connectionVersion !== this._connectionVersion) {
                this.stopListening(subscription);
                return;
            }
            this._subscription = subscription;
            this._hasStreamingError = false;
            // Catch changes committed between the initial lookup and subscription acknowledgement.
            this.checkAuthentication(this._requestVersion);
        } catch (error) {
            if (this.isConnected && connectionVersion === this._connectionVersion) {
                this.showStreamingError(error);
            }
        } finally {
            if (connectionVersion === this._connectionVersion) {
                this._subscriptionPending = false;
            }
        }
    }

    stopListening(subscription) {
        return unsubscribe(subscription, (result) => {
            if (!result.successful) {
                console.error('Unable to unsubscribe from call authentication changes:', result);
            }
        }).catch((error) => console.error('Unable to unsubscribe from call authentication changes:', error));
    }

    clearSubscription() {
        this._connectionVersion += 1;
        this._subscriptionPending = false;
        this._hasStreamingError = false;
        if (this._subscription) {
            this.stopListening(this._subscription);
            this._subscription = null;
        }
    }

    showStreamingError(error) {
        if (!this._hasStreamingError) {
            console.error('Unable to receive call authentication changes:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Automatisk BankID-oppdatering er utilgjengelig',
                    message: 'BankID-status kan være utdatert fordi sanntidsforbindelsen er utilgjengelig.',
                    variant: 'warning'
                })
            );
        }
        this._hasStreamingError = true;
    }

    resetAuthentication() {
        this._requestVersion += 1;
        this._lookupVersion = null;
        this._refreshQueued = false;
        this._hasLookupError = false;
        this.isAuthenticated = false;
    }

    showError(error, message = 'BankID-status kunne ikke hentes.') {
        console.error('Unable to retrieve call authentication status:', error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Kunne ikke hente BankID-status',
                message,
                variant: 'error'
            })
        );
    }
}
