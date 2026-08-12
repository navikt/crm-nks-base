import { LightningElement, api, wire } from 'lwc';
import getReverseRelatedRecord from '@salesforce/apex/NksRecordInfoController.getReverseRelatedRecord';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONVERSATION_NOTE_OBJECT from '@salesforce/schema/Conversation_Note__c';
import CHANGE_USER_LABEL from '@salesforce/label/c.NKS_Change_User';
import CREATE_TASK_LABEL from '@salesforce/label/c.NKS_Create_NAV_Task';
import { publishToAmplitude } from 'c/amplitude';
import {
    handleShowNotifications,
    getOutputVariableValue,
    addSuccessNotification,
    addErrorNotification
} from 'c/nksComponentsUtils';
import CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL from '@salesforce/messageChannel/conversationNoteNotifications__c';
import BUTTON_CONTAINER_NOTIFICATIONS_CHANNEL from '@salesforce/messageChannel/buttonContainerNotifications__c';
import { subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import postOppgave from '@salesforce/apex/OppgaveManager.postTaskFromLwc';

export default class NksConversationNoteDetails extends LightningElement {
    @api recordId;
    @api objectApiName;

    navTasks = [];
    notes = [];
    expanded = true;
    changeUserLabel = CHANGE_USER_LABEL;
    createTaskLabel = CREATE_TASK_LABEL;
    conversationNoteSubscription = null;
    buttonContainerSubscription = null;
    flowButtonLabel;
    flowApiName;
    _wiredRecord;

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    @wire(MessageContext)
    messageContext;

    @wire(getObjectInfo, { objectApiName: CONVERSATION_NOTE_OBJECT })
    objectInfo;

    @wire(getReverseRelatedRecord, {
        parentId: '$recordId',
        queryFields: 'Id, CRM_Conversation_Note__c, createddate, CRM_Theme__r.Name, CRM_Theme_Group__r.Name',
        objectApiName: 'Conversation_Note__c',
        relationshipField: 'CRM_Case__c',
        ordering: 'createddate asc'
    })
    wiredData(result) {
        this._wiredRecord = result;
        const { data, error } = result;
        if (data) {
            this.notes = data.map((x) => {
                return { ...x, name: x.CRM_Theme__r ? x.CRM_Theme__r?.Name : x.CRM_Theme_Group__r?.Name };
            });
        } else if (error) {
            console.error('Error fetching reverse related records:', error);
        }
    }

    get recordLabel() {
        return this.objectInfo?.data?.label || 'Samtalereferat';
    }

    get inputVariables() {
        return [{ name: 'recordId', type: 'String', value: this.recordId }];
    }

    get reverseExpanded() {
        return !this.expanded;
    }

    get sectionClasses() {
        return `slds-section slds-var-p-horizontal_medium slds-var-p-top_small slds-m-vertical_none ${
            this.expanded ? 'slds-is-open' : ''
        }`;
    }

    get hasCNotes() {
        return this.notes != null && this.notes.length > 0;
    }

    get notificationBoxTemplate() {
        return this.template.querySelector('c-nks-notification-box');
    }

    handleShowButtons(outputVariables) {
        const hasReadAccess = getOutputVariableValue(outputVariables, 'HAS_PERSON_READ');
        const hasNoAccount = getOutputVariableValue(outputVariables, 'HAS_NO_ACCOUNT');
        this.flowButtonLabel = hasReadAccess || hasNoAccount ? this.changeUserLabel : this.createTaskLabel;
        this.flowApiName = hasReadAccess || hasNoAccount ? 'NKS_Case_Change_Account' : 'NKS_Case_Send_NAV_Task';
    }

    handleStatusChange(event) {
        const { status, outputVariables } = event.detail;

        this.handleShowButtons(outputVariables);

        if (status === 'STARTED') {
            this.notificationBoxTemplate?.clearNotificationsByVariant('error');
            return;
        }

        if (
            status === 'FINISHED' &&
            outputVariables?.some((output) => output.objectType === 'Conversation_Note__c' && output.value !== null)
        ) {
            publishToAmplitude('Conversation Note Created');
            refreshApex(this._wiredRecord);
            handleShowNotifications('journal_conversation', outputVariables, this.notificationBoxTemplate, true);
            this.handleSendingNavTasks(outputVariables);
        }
    }

    handleChange(event) {
        if (event.detail) {
            const { value } = event.detail;
            let message = {
                eventType: 'ThemeCategorization',
                properties: { value: value }
            };
            message.eventType +=
                value === 'GENERELL_SAK' || value === 'FAGSAK' ? ' - Sakstype endret' : ' - Theme/Gjelder changed';
            publishToAmplitude('ThemeCategorization', { value: value });
        }
    }

    handleExpandClick() {
        this.expanded = !this.expanded;
    }

    subscribeToMessageChannel() {
        if (!this.conversationNoteSubscription) {
            this.conversationNoteSubscription = subscribe(
                this.messageContext,
                CONVERSATION_NOTE_NOTIFICATIONS_CHANNEL,
                (message) => this.handleMessageFromLMSChannel(message),
                { scope: APPLICATION_SCOPE }
            );
        }

        if (!this.buttonContainerSubscription) {
            this.buttonContainerSubscription = subscribe(
                this.messageContext,
                BUTTON_CONTAINER_NOTIFICATIONS_CHANNEL,
                (message) => this.handleMessageFromLMSChannel(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        if (this.conversationNoteSubscription) {
            unsubscribe(this.conversationNoteSubscription);
            this.conversationNoteSubscription = null;
        }

        if (this.buttonContainerSubscription) {
            unsubscribe(this.buttonContainerSubscription);
            this.buttonContainerSubscription = null;
        }
    }

    handleMessageFromLMSChannel(message) {
        if (this.recordId === message.recordId) {
            const navTaskOutput = getOutputVariableValue(message.outputVariables, 'navTaskOutput');
            if (navTaskOutput) {
                const selectedUnitName = getOutputVariableValue(message.outputVariables, 'Selected_Unit_Name');
                this.navTasks.push({ ...navTaskOutput, selectedUnitName });
            }
            handleShowNotifications(message.flowApiName, message.outputVariables, this.notificationBoxTemplate);
        }
    }

    async handleSendingNavTasks(outputVariables) {
        try {
            const behandlingskjedeId = getOutputVariableValue(outputVariables, 'CONV_NOTE_API_REFERENCE') ?? null;
            this.sendNavTasks(behandlingskjedeId);
        } catch (error) {
            console.error('Problem handling navTasks:', JSON.stringify(error));
        }
    }

    sendNavTasks(behandlingskjedeId) {
        this.notificationBoxTemplate.filterNotification('Oppgaven er lagret');
        const tasksToSend = [...this.navTasks];
        this.navTasks = [];

        tasksToSend.forEach((navTask) => {
            const { selectedUnitName, ...taskFields } = navTask;
            const rawRequest = behandlingskjedeId
                ? { ...taskFields, eksternHenvendelseId: behandlingskjedeId }
                : taskFields;
            const requestJson = JSON.stringify(rawRequest);
            postOppgave({ requestJson })
                .then((result) => {
                    if (result?.isSuccess) {
                        const unitText = `${navTask.tildeltEnhetsnr ?? ''}${navTask.selectedUnitName ? ` ${navTask.selectedUnitName}` : ''}`;
                        const optionalText = `${navTask.tema ? `${navTask.tema}\xa0\xa0\xa0\xa0\xa0` : ''}Sendt til: ${unitText}`;
                        addSuccessNotification(this.notificationBoxTemplate, 'Oppgave opprettet', optionalText);
                    } else if (result && !result.isSuccess) {
                        const text = result.isRetry
                            ? 'Oppgaveopprettelse feilet. Oppgaven vil bli automatisk opprettet på et senere tidspunkt.'
                            : 'Oppgaveopprettelse feilet.';
                        addErrorNotification(this.notificationBoxTemplate, text, result.errorMessage);
                    }
                })
                .catch((error) => {
                    addErrorNotification(
                        this.notificationBoxTemplate,
                        'Oppgaveopprettelse feilet.',
                        error?.body?.message ?? error?.message
                    );
                });
        });
    }
}
