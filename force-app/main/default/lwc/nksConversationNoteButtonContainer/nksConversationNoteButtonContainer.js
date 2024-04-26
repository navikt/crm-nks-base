import { LightningElement, api } from 'lwc';
import JOURNAL_LABEL from '@salesforce/label/c.NKS_Journal';
import CREATE_NAV_TASK_LABEL from '@salesforce/label/c.NKS_Create_NAV_Task';
import BACK_LABEL from '@salesforce/label/c.NKS_Back';
import CONVERSATION_NOTE_CREATE_LABEL from '@salesforce/label/c.NKS_Create_Conversation_Note';
import { publishToAmplitude } from 'c/amplitude';

const DATA_IDS = {
    CREATE_NAV_TASK: 'createNavTask',
    JOURNAL: 'journal',
    JOURNAL_AND_SHARE: 'journalAndShare'
};

export default class NksSamtalereferatButtonContainer extends LightningElement {
    @api recordId;
    @api conversationNoteButtonLabel;
    @api journalButtonDataId = DATA_IDS.JOURNAL;

    showFlow = false;
    showCreateTaskFlow = false;
    showJournalFlow = false;
    labels = {
        createNavTask: CREATE_NAV_TASK_LABEL,
        back: BACK_LABEL,
        journal: JOURNAL_LABEL,
        createConversationNote: CONVERSATION_NOTE_CREATE_LABEL
    };
    dataId = '';
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
        return this.dataId === DATA_IDS.JOURNAL_AND_SHARE;
    }

    get conversationNoteButtonVariant() {
        return this.conversationNoteButtonLabel === this.labels.createConversationNote ? 'brand-outline' : 'brand';
    }

    toggleFlow(event) {
        this.showFlow = !this.showFlow;
        if (event.target && event.target.dataset.id) {
            this.dataId = event.target.dataset.id;
            if (this.isJournalAndShare) {
                this._journalConversation = true;
            }
            this.handleShowFlow();
            this.changeColor(this.dataId);
            if (event.target.label) {
                publishToAmplitude('Conversation note', { type: event.target.label + ' pressed' });
            }
        }
    }

    handleShowFlow() {
        this.showCreateTaskFlow = this.dataId === DATA_IDS.CREATE_NAV_TASK;
        this.showJournalFlow = this.dataId === DATA_IDS.JOURNAL;
    }

    handleStatusChange(event) {
        let flowStatus = event.detail.status;
        if (flowStatus === 'FINISHED' || flowStatus === 'FINISHED_SCREEN') {
            this.showFlow = false;
        }
    }

    changeColor(dataId) {
        const buttons = this.template.querySelectorAll('lightning-button');
        buttons.forEach((button) => {
            button.classList.remove('active');
        });
        let currentButton = this.template.querySelector(`lightning-button[data-id="${dataId}"]`);
        if (currentButton && this.showFlow) {
            currentButton.classList.add('active');
            currentButton.blur();
        }
    }
}
