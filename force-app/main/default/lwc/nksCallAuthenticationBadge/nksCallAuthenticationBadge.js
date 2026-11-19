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
const INITIAL_RETRY_DELAY = 2000;
const MAX_RETRY_DELAY = 30000;
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
    _retryTimer;
    _retryDelay = INITIAL_RETRY_DELAY;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        if (value !== this._recordId) {
            this.resetAuthentication();
            this._caseContext = null;
            this._canCheck = false;
            this._sessionId = null;
            this._initialAccountId = undefined;
            this._recordId = value;
        }
    }

    connectedCallback() {
        this._streamingErrorListener = (error) => {
            if (!error.channel || error.channel === CHANNEL || error.channel.startsWith('/meta/')) {
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
        this._connectionVersion += 1;
        this._subscriptionPending = false;
        streamingErrorListeners.delete(this._streamingErrorListener);
        if (this._subscription) {
            this.stopListening(this._subscription);
            this._subscription = null;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
    wiredCase({ data, error }) {
        if (error) {
            this.resetAuthentication();
            this._caseContext = null;
            this._canCheck = false;
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
                this.checkAuthentication(this._requestVersion);
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
                this.updateRecovery();
            }
        }
    }

    async startListening() {
        if ((this._subscription && !this._hasStreamingError) || this._subscriptionPending || !this.isConnected) {
            return;
        }
        const connectionVersion = ++this._connectionVersion;
        this._subscriptionPending = true;
        try {
            if (this._subscription) {
                const subscription = this._subscription;
                this._subscription = null;
                await this.stopListening(subscription);
            }
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
                this.updateRecovery();
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

    updateRecovery() {
        if (!this.isConnected || !this._canCheck || (!this._hasLookupError && !this._hasStreamingError)) {
            clearTimeout(this._retryTimer);
            this._retryTimer = null;
            this._retryDelay = INITIAL_RETRY_DELAY;
            return;
        }
        if (this._retryTimer) {
            return;
        }
        // Only retry failures; healthy subscriptions never poll.
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._retryTimer = setTimeout(() => {
            this._retryTimer = null;
            this.startListening();
            this.checkAuthentication(this._requestVersion);
        }, this._retryDelay);
        this._retryDelay = Math.min(this._retryDelay * 2, MAX_RETRY_DELAY);
    }

    showStreamingError(error) {
        if (!this._hasStreamingError) {
            console.error('Unable to receive call authentication changes:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Automatisk BankID-oppdatering er utilgjengelig',
                    message: 'Sanntidsforbindelsen er utilgjengelig. Status hentes automatisk med nye forsøk.',
                    variant: 'warning'
                })
            );
        }
        this._hasStreamingError = true;
        this.updateRecovery();
    }

    resetAuthentication() {
        clearTimeout(this._retryTimer);
        this._retryTimer = null;
        this._retryDelay = INITIAL_RETRY_DELAY;
        this._requestVersion += 1;
        this._lookupVersion = null;
        this._refreshQueued = false;
        this._hasLookupError = false;
        this.isAuthenticated = false;
    }

    showError(error, message = 'BankID-status kunne ikke hentes. Prøver igjen automatisk.') {
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
