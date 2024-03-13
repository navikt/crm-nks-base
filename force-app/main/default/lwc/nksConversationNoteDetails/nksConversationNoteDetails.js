import { LightningElement, api, wire } from 'lwc';
import getReverseRelatedRecord from '@salesforce/apex/NksRecordInfoController.getReverseRelatedRecord';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONVERSATION_NOTE_OBJECT from '@salesforce/schema/Conversation_Note__c';
import CHANGE_USER_LABEL from '@salesforce/label/c.NKS_Change_User';
import { publishToAmplitude } from 'c/amplitude';

export default class NksSamtalereferatDetails extends LightningElement {
    @api recordId;

    dataShowing;
    notes;
    expanded = true;
    changeUserLabel = CHANGE_USER_LABEL;
    showFlow = false;

    @wire(getObjectInfo, { objectApiName: CONVERSATION_NOTE_OBJECT })
    objectInfo;

    @wire(getReverseRelatedRecord, {
        parentId: '$recordId',
        queryFields: 'Id, CRM_conversation_note__c, createddate, CRM_Theme__r.Name, CRM_Theme_Group__r.Name',
        objectApiName: 'Conversation_note__c',
        relationshipField: 'CRM_case__c',
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
            console.log(error);
        }
    }

    get recordLabel() {
        return this.objectInfo?.data?.label ? this.objectInfo.data.label : 'Samtalereferat';
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

    get reverseExpanded() {
        return !this.expanded;
    }

    get sectionClasses() {
        return (
            'slds-section slds-var-m-horizontal_small slds-var-p-bottom_xx-small' +
            (this.expanded ? ' slds-is-open' : '')
        );
    }

    get hasCNotes() {
        return this.notes != null && this.notes.length > 0;
    }

    handleStatusChange(event) {
        const { status, outputVariables } = event.detail;
        if (
            status === 'FINISHED' &&
            outputVariables?.some((output) => output.objectType === 'Conversation_Note__c' && output.value !== null)
        ) {
            publishToAmplitude('Conversation Note Journaled');
            refreshApex(this._wiredRecord);
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

    toggleFlow(event) {
        publishToAmplitude('Action', { type: event.target.label + ' pressed' });
        this.showFlow = !this.showFlow;
    }
}
