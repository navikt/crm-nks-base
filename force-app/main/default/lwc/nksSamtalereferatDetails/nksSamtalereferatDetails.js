import { LightningElement, api, wire } from 'lwc';
import getReverseRelatedRecord from '@salesforce/apex/NksRecordInfoController.getReverseRelatedRecord';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONVERSATION_NOTE_OBJECT from '@salesforce/schema/Conversation_note__c';
import { MessageContext, publish } from 'lightning/messageService';
import AMPLITUDE_CHANNEL from '@salesforce/messageChannel/amplitude__c';

export default class NksSamtalereferatDetails extends LightningElement {
    @api recordId;
    dataShowing;
    notes;
    expanded = true;

    @wire(MessageContext)
    messageContext;

    @wire(getObjectInfo, { objectApiName: CONVERSATION_NOTE_OBJECT })
    objectInfo;

    renderedCallback() {
        console.log(this.objectInfo);
    }
    
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
                return { ...x, name: x.CRM_Theme__r ? x.CRM_Theme__r.Name : x.CRM_Theme_Group__r.Name };
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
        return 'slds-section slds-var-m-horizontal_small' + (this.expanded ? ' slds-is-open' : '');
    }

    get hasCNotes() {
        return this.notes != null && this.notes.length > 0;
    }

    handleStatusChange(event) {
        const { status, outputVariables } = event.detail;
        if (status === 'FINISHED' &&
            outputVariables?.some(
                (output) => output.objectType === 'Conversation_Note__c' && output.value !== null
            )
        ) {
            let message = {
                eventType: 'Conversation Note Journaled',
            };
            publish(this.messageContext, AMPLITUDE_CHANNEL, message);
            refreshApex(this._wiredRecord);
        }        
    }

    handleChange(event) {;
        if (event.detail) {
            const { value } = event.detail;
            let message = {
                eventType: 'ThemeCategorization',
                properties: { value: value }
            };
            value === 'GENERELL_SAK' || value === 'FAGSAK' ? message.eventType += ' - Sakstype endret' : message.eventType += ' - Theme/Gjelder changed';
            publish(this.messageContext, AMPLITUDE_CHANNEL, message);
        }
    }

    handleExpandClick() {
        this.expanded = !this.expanded;
    }
}
