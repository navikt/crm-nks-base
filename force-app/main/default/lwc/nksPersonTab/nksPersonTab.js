import { LightningElement, api, wire } from 'lwc';
import DETAILS_TAB_LABEL from '@salesforce/label/c.NKS_Details_Tab_Label';
import COMMUNICATION_TAB_LABEL from '@salesforce/label/c.NKS_Communication_Tab_Label';
import TASKS_TAB_LABEL from '@salesforce/label/c.NKS_Tasks_Tab_Label';
import DOCUMENTS_TAB_LABEL from '@salesforce/label/c.NKS_Documents_Tab_Label';
import PAYOUT_TAB_LABEL from '@salesforce/label/c.NKS_Payout_Tab_Label';
import CASES_TAB_LABEL from '@salesforce/label/c.NKS_Cases_Tab_Label';
import CASE_ACCOUNT_FIELD from '@salesforce/schema/Case.AccountId';
import ACCOUNT_ID_FIELD from '@salesforce/schema/Account.Id';
import ACCOUNT_PERSON_FIELD from '@salesforce/schema/Account.CRM_Person__c';
import MOVED_FIELD from '@salesforce/schema/Person__c.INT_MovedToCountry__c';
import PERSON_ACTORID_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

export default class NksPersonTab extends LightningElement {
    @api recordId;
    @api objectApiName;
    relatedListDisabled = false;
    relatedListHeading = '';

    // TODO: Use labels for english/norwegian
    details = DETAILS_TAB_LABEL;
    communication = COMMUNICATION_TAB_LABEL;
    tasks = TASKS_TAB_LABEL;
    documents = DOCUMENTS_TAB_LABEL;
    payout = PAYOUT_TAB_LABEL;
    cases = CASES_TAB_LABEL;

    personId;
    accountId;
    accountField;
    actorId;
    movedCountry;

    connectedCallback() {
        if (this.objectApiName === 'Case') {
            this.accountField = [CASE_ACCOUNT_FIELD];
            return;
        }
        if (this.objectApiName === 'Account') {
            this.accountId = this.recordId;
            this.accountField = [ACCOUNT_ID_FIELD];
        }
    }

    get relationshipField() {
        if (this.objectApiName === 'Case') {
            return 'Account.CRM_Person__c';
        } else if (this.objectApiName === 'Account') {
            return 'CRM_Person__c';
        }
        return null;
    }

    get personIdent() {
        if (this.objectApiName === 'Case') {
            return 'Account.INT_PersonIdent__c	';
        } else if (this.objectApiName === 'Account') {
            return 'INT_PersonIdent__c';
        }
        return null;
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$accountField'
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
            if (this.accountField) {
                this.accountId = getFieldValue(data, this.accountField[0]);
            }
        }
        if (error) {
            console.log('error: ');
            console.log(error);
        }
    }

    @wire(getRecord, {
        recordId: '$accountId',
        fields: [ACCOUNT_PERSON_FIELD]
    })
    wiredAccountInfo({ error, data }) {
        if (data) {
            this.personId = getFieldValue(data, ACCOUNT_PERSON_FIELD);
        }

        if (error) {
            console.log('error: ');
            console.log(error);
        }
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: [PERSON_ACTORID_FIELD, MOVED_FIELD]
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            this.actorId = getFieldValue(data, PERSON_ACTORID_FIELD);
            this.movedCountry = getFieldValue(data, MOVED_FIELD);
        }

        if (error) {
            console.log('error:');
            console.log(error);
        }
    }

    get tabConditional() {
        return this.actorId != null;
    }

    get flyttingConditional() {
        return this.movedCountry != null;
    }

    handleTabClick(event) {
        console.log('First');
        const tabContent2 = `Tab ${event.target.label} is now active`;
        console.log(tabContent2);
    }

    receiveHeading(event) {
        this.relatedListHeading = event.detail;
    }

    updateLoadMore(event) {
        this.relatedListDisabled = !event.detail.enabled;
    }

    get loadMoreDisabled() {
        return this.relatedListDisabled;
    }

    loadMore() {
        console.log('Bink');
        this.template.querySelector('c-nks-filtered-related-list').loadMore();
    }

    beginRefresh() {
        this.template.querySelector('c-nks-filtered-related-list').refreshList();
    }
}
