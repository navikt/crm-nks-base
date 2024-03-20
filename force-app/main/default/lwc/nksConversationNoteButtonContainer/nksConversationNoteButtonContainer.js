import { LightningElement, api } from 'lwc';
import JOURNAL_SHARE_WITH_USER_LABEL from '@salesforce/label/c.NKS_Journal_Share_With_User';
//import CREATE_NAV_TASK_LABEL from '@salesforce/label/c.NKS_Create_NAV_Task';
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

    //createNavTask = CREATE_NAV_TASK_LABEL;
    journalAndShare = JOURNAL_SHARE_WITH_USER_LABEL;
    back = BACK_LABEL;
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
        return this.label === this.journalAndShare;
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
    }
}
