import { LightningElement, api, wire } from 'lwc';
import getReverseRelatedRecord from '@salesforce/apex/NksRecordInfoController.getReverseRelatedRecord';
import { refreshApex } from '@salesforce/apex';

export default class NksSamtalereferatDetails extends LightningElement {
    @api recordId;
    dataShowing;
    notes;
    expanded = true;

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
            console.log('Yo');
            this.notes = data;
            console.log(JSON.stringify(this.notes));
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

    handleChange(event) {
        if (
            event.detail.status === 'FINISHED' &&
            event.detail.outputVariables?.some(
                (output) => output.objectType === 'Conversation_Note__c' && output.value !== null
            )
        )
            refreshApex(this._wiredRecord);
    }

    handleExpandClick(event) {
        console.log('Heisann');
        console.log(this.expanded);
        this.expanded = !this.expanded;
    }
}
