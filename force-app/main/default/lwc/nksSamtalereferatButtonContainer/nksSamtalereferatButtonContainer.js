import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import ISCLOSED_FIELD from '@salesforce/schema/Case.IsClosed';
import SHARE_WITH_USER_LABEL from '@salesforce/label/c.NKS_Conversation_Note_Share_With_User';
import JOURNAL_LABEL from '@salesforce/label/c.NKS_Journal_Button_Label';
import CREATE_NAV_TASK_LABEL from '@salesforce/label/c.NKS_Create_Task_Button_Label';
import BACK_LABEL from '@salesforce/label/c.NKS_Back_Button_Label';
import NEW_CONVERSATION_NOTE_LABEL from '@salesforce/label/c.NKS_New_Conversation_Note';
import { publishToAmplitude } from 'c/amplitude';

export default class NksSamtalereferatButtonContainer extends LightningElement {
    @api recordId;

    showFlow = false;
    showCreateTaskFlow = false;
    showJournalFlow = false;

    createNavTask = CREATE_NAV_TASK_LABEL;
    journal = JOURNAL_LABEL;
    shareWithUser = SHARE_WITH_USER_LABEL;
    back = BACK_LABEL;
    label;

    get inputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    get ariaExpanded() {
        return this.showFlow.toString();
    }

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD, ISCLOSED_FIELD] })
    wiredRecord(result) {
        this.wiredCase = result;
        const { data, error } = result;
        if (data) {
            this.status = getFieldValue(data, STATUS_FIELD);
            this.closed = getFieldValue(data, ISCLOSED_FIELD);
        } else if (error) {
            console.log(error.body.message);
        }
    }

    flowFinishHandler() {
        refreshApex(this.wiredCase);
    }

    toggleFlow(event) {
        publishToAmplitude('Action', { type: this.buttonLabel + ' pressed' });
        this.showFlow = !this.showFlow;
        this.label = event.currentTarget.label;
        this.handleShowFlow();
    }

    handleShowFlow() {
        if (this.label === 'Create NAV Task') {
            this.showCreateTaskFlow = true;
            this.showJournalFlow = false;
        }

        if (this.label === 'Journal') {
            this.showCreateTaskFlow = false;
            this.showJournalFlow = true;
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
