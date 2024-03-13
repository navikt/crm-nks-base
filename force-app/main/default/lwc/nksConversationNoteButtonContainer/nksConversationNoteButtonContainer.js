import { LightningElement, api } from 'lwc';
import JOURNAL_SHARE_WITH_USER_LABEL from '@salesforce/label/c.NKS_Journal_Share_With_User';
import JOURNAL_LABEL from '@salesforce/label/c.NKS_Journal';
import CREATE_NAV_TASK_LABEL from '@salesforce/label/c.NKS_Create_NAV_Task';
import { publishToAmplitude } from 'c/amplitude';

export default class NksSamtalereferatButtonContainer extends LightningElement {
    @api recordId;
    @api conversationNoteButtonLabel;
    @api journalButtonLabel;
    @api journalFlowName;

    showFlow = false;
    showCreateTaskFlow = false;
    showJournalFlow = false;
    isJournalAndShare = false;

    createNavTask = CREATE_NAV_TASK_LABEL;
    journal = JOURNAL_LABEL;
    journalAndShare = JOURNAL_SHARE_WITH_USER_LABEL;
    _journalConversation;

    @api
    get journalConversation() {
        return this._journalConversation;
    }

    set journalConversation(value) {
        this._journalConversation = value;
    }

    get inputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    toggleFlow(event) {
        let label = event.target.label;
        this.showFlow = !this.showFlow;

        if (label === this.journalAndShare) {
            this._journalConversation = true;
            this.isJournalAndShare = true;
        }
        this.handleShowFlow();
        publishToAmplitude('Action', { type: label + ' pressed' });
    }

    handleShowFlow() {
        if (this.label === this.createNavTask) {
            this.showCreateTaskFlow = true;
            this.showJournalFlow = false;
        }

        if (this.label === this.journal) {
            this.showJournalFlow = true;
            this.showCreateTaskFlow = false;
        }
    }

    handleStatusChange(event) {
        let flowStatus = event.detail.status;
        if (flowStatus === 'FINISHED' || flowStatus === 'FINISHED_SCREEN') {
            this.showFlow = false;
        }
        this.dispatchEvent(new CustomEvent('flowfinished'));
    }
}
