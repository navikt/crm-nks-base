import { LightningElement, api } from 'lwc';
import JOURNAL_SHARE_WITH_USER_LABEL from '@salesforce/label/c.NKS_Journal_Share_With_User';
import JOURNAL_LABEL from '@salesforce/label/c.NKS_Journal_Button_Label';
import CREATE_NAV_TASK_LABEL from '@salesforce/label/c.NKS_Create_Task_Button_Label';
import { publishToAmplitude } from 'c/amplitude';

export default class NksSamtalereferatButtonContainer extends LightningElement {
    @api recordId;
    @api conversationNoteButtonLabel;
    @api journalButtonLabel;
    @api journalFlowName;
    @api conversationNote;

    showFlow = false;
    showCreateTaskFlow = false;
    showJournalFlow = false;
    showJournalAndShareFlow = false;
    createNavTask = CREATE_NAV_TASK_LABEL;
    journal = JOURNAL_LABEL;
    journalAndShare = JOURNAL_SHARE_WITH_USER_LABEL;
    label;

    get inputVariables() {
        if (this.label === this.journalAndShare) {
            return [
                {
                    name: 'recordId',
                    type: 'String',
                    value: this.recordId
                },
                {
                    name: 'conversationNote',
                    type: 'String',
                    value: this.conversationNote
                }
            ];
        }
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    toggleFlow(event) {
        this.showFlow = !this.showFlow;
        this.label = event.currentTarget.label;
        this.handleShowFlow();
        publishToAmplitude('Action', { type: this.label + ' pressed' });
    }

    handleShowFlow() {
        if (this.label === this.createNavTask) {
            this.showCreateTaskFlow = true;
            this.showJournalFlow = false;
            this.showJournalAndShareFlow = false;
        }

        if (this.label === this.journal) {
            this.showJournalFlow = true;
            this.showCreateTaskFlow = false;
            this.showJournalAndShareFlow = false;
        }

        if (this.label === this.journalAndShare) {
            this.showJournalAndShareFlow = true;
            this.showCreateTaskFlow = false;
            this.showJournalFlow = false;
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
