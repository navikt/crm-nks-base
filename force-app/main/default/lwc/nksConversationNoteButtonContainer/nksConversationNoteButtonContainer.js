import { LightningElement, api } from 'lwc';
import JOURNAL_SHARE_WITH_USER_LABEL from '@salesforce/label/c.NKS_Journal_Share_With_User';
import JOURNAL_LABEL from '@salesforce/label/c.NKS_Journal';
import CREATE_NAV_TASK_LABEL from '@salesforce/label/c.NKS_Create_NAV_Task';
import BACK_LABEL from '@salesforce/label/c.NKS_Back';
import { publishToAmplitude } from 'c/amplitude';

export default class NksSamtalereferatButtonContainer extends LightningElement {
    @api recordId;
    @api conversationNoteButtonLabel;
    @api journalButtonLabel;
    @api journalFlowName;
    @api showBackButton = false;

    showFlow = false;
    showCreateTaskFlow = false;
    showJournalFlow = false;
    labels = { CREATE_NAV_TASK_LABEL, JOURNAL_SHARE_WITH_USER_LABEL, BACK_LABEL, JOURNAL_LABEL };
    label;
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

    get isJournalAndShare() {
        return this.label === this.labels.JOURNAL_SHARE_WITH_USER_LABEL;
    }

    toggleFlow(event) {
        this.showFlow = !this.showFlow;
        this.label = event.target.label;
        if (this.isJournalAndShare) {
            this._journalConversation = true;
        }
        this.handleShowFlow();
        publishToAmplitude('Covnersation note', { type: this.label + ' pressed' });
    }

    handleShowFlow() {
        this.showCreateTaskFlow = this.label === this.labels.CREATE_NAV_TASK_LABEL;
        this.showJournalFlow = this.label === this.labels.JOURNAL_LABEL;
    }

    handleStatusChange(event) {
        let flowStatus = event.detail.status;
        if (flowStatus === 'FINISHED' || flowStatus === 'FINISHED_SCREEN') {
            this.showFlow = false;
        }
    }
}
