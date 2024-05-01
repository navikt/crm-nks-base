import { LightningElement, api } from 'lwc';
import JOURNAL_LABEL from '@salesforce/label/c.NKS_Journal';
import CREATE_NAV_TASK_LABEL from '@salesforce/label/c.NKS_Create_NAV_Task';
import CONVERSATION_NOTE_NEW_LABEL from '@salesforce/label/c.NKS_New_Conversation_Note';
import { publishToAmplitude } from 'c/amplitude';

const DATA_IDS = {
    CREATE_NAV_TASK: 'createNavTask',
    JOURNAL: 'journal'
};

export default class NksSamtalereferatButtonContainer extends LightningElement {
    @api recordId;
    @api conversationNoteButtonLabel;
    @api journalAndShare = false;

    showFlow = false;
    labels = {
        createNavTask: CREATE_NAV_TASK_LABEL,
        journal: JOURNAL_LABEL,
        newConversationNote: CONVERSATION_NOTE_NEW_LABEL
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

    get conversationNoteButtonVariant() {
        return this.conversationNoteButtonLabel === this.labels.newConversationNote ? 'brand-outline' : 'brand';
    }

    get showCreateNavTaskFlow() {
        return this.showFlow && this.dataId === DATA_IDS.CREATE_NAV_TASK;
    }

    get showJournalFlow() {
        return this.showFlow && this.dataId === DATA_IDS.JOURNAL;
    }

    get isJournalAndShare() {
        return this.journalConversation && !this.showCreateNavTaskFlow;
    }

    toggleFlow(event) {
        this.showFlow = !this.showFlow;
        if (this.journalAndShare) {
            this._journalConversation = true;
        }
        if (event.target?.dataset.id) {
            this.dataId = event.target.dataset.id;
            this.changeColor(this.dataId);
        }
        publishToAmplitude('Conversation note', { type: event.target?.label + ' pressed' });
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
        }
    }
}
