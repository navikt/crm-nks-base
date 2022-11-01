import { LightningElement, api, wire } from 'lwc';
import getReverseRelatedRecord from '@salesforce/apex/NksRecordInfoController.getReverseRelatedRecord';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONVERSATION_NOTE_OBJECT from '@salesforce/schema/Conversation_note__c';

export default class NksSamtalereferatDetails extends LightningElement {
    @api recordId;
    dataShowing;
    notes;
    expanded = true;

    @wire(getObjectInfo, { objectApiName: CONVERSATION_NOTE_OBJECT })
    objectInfo;

    renderedCallback() {
        console.log(this.objectInfo);
    }

    @wire(getReverseRelatedRecord, {
        parentId: '$recordId',
        queryFields: 'Id, CRM_conversation_note__c, createddate, CRM_Theme__r.Name',
        objectApiName: 'Conversation_note__c',
        relationshipField: 'CRM_case__c',
        ordering: 'createddate asc'
    })
    wiredData(result) {
        this._wiredRecord = result;
        const { data, error } = result;
        if (data) {
            this.notes = data;
        } else if (error) {
            console.log(error);
        }
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

    handleChange(event) {
        if (
            event.detail.status === 'FINISHED' &&
            event.detail.outputVariables?.some(
                (output) => output.objectType === 'Conversation_Note__c' && output.value !== null
            )
        )
            refreshApex(this._wiredRecord);
    }

    handleExpandClick() {
        this.expanded = !this.expanded;
    }
}
