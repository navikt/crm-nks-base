import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCallAuthenticationStatus from '@salesforce/apex/NKS_CallFlowController.getCallAuthenticationStatus';
import ACCOUNT_FIELD from '@salesforce/schema/Case.AccountId';
import ORIGIN_FIELD from '@salesforce/schema/Case.Origin';
import SESSION_FIELD from '@salesforce/schema/Case.NKS_Puzzel_Session_Id__c';

const CASE_FIELDS = [ACCOUNT_FIELD, ORIGIN_FIELD, SESSION_FIELD];
const MAX_ATTEMPTS = 12;
const RETRY_DELAY = 5000;

export default class NksCallAuthenticationBadge extends LightningElement {
    isAuthenticated = false;
    _recordId;
    _initialAccountId;
    _caseContext;
    _requestVersion = 0;
    _attempts = 0;
    _retryTimer;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        if (value !== this._recordId) {
            this.resetAuthentication();
            this._caseContext = null;
            this._initialAccountId = undefined;
            this._recordId = value;
        }
    }

    disconnectedCallback() {
        this.resetAuthentication();
        this._caseContext = null;
    }

    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
    wiredCase({ data, error }) {
        if (error) {
            this.resetAuthentication();
            this._caseContext = null;
            this.showError(error);
        } else if (data && data.id === this.recordId) {
            const accountId = data.fields.AccountId.value;
            const sessionId = data.fields.NKS_Puzzel_Session_Id__c.value;
            const origin = data.fields.Origin.value;
            if (this._initialAccountId === undefined) {
                this._initialAccountId = accountId;
            }
            const context = JSON.stringify([data.id, accountId, sessionId, origin]);
            if (context === this._caseContext) {
                return;
            }
            this.resetAuthentication();
            this._caseContext = context;
            if (origin === 'Phone' && accountId && accountId === this._initialAccountId && sessionId) {
                this.checkAuthentication(this._requestVersion);
            }
        }
    }

    async checkAuthentication(requestVersion) {
        if (!this.isConnected || requestVersion !== this._requestVersion) {
            return;
        }
        this._attempts += 1;
        try {
            const result = await getCallAuthenticationStatus({ caseId: this.recordId });
            if (!this.isConnected || requestVersion !== this._requestVersion) {
                return;
            }
            this.isAuthenticated = result.isAuthenticated === true;
            if (result.shouldRetry && this._attempts < MAX_ATTEMPTS) {
                // EnquiryLog may be created after the case is opened.
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                this._retryTimer = setTimeout(() => this.checkAuthentication(requestVersion), RETRY_DELAY);
            }
        } catch (error) {
            if (this.isConnected && requestVersion === this._requestVersion) {
                this.isAuthenticated = false;
                this.showError(error);
            }
        }
    }

    resetAuthentication() {
        clearTimeout(this._retryTimer);
        this._retryTimer = null;
        this._requestVersion += 1;
        this._attempts = 0;
        this.isAuthenticated = false;
    }

    showError(error) {
        console.error('Unable to retrieve call authentication status:', error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Kunne ikke hente BankID-status',
                message: 'BankID-status kunne ikke hentes. Last inn saken på nytt for å prøve igjen.',
                variant: 'error'
            })
        );
    }
}
