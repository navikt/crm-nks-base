import { LightningElement, api, wire } from 'lwc';
import nksSingleValueUpdate from '@salesforce/messageChannel/nksSingleValueUpdate__c';
import { publish, MessageContext } from 'lightning/messageService';

export default class NksSingleRecordInputField extends LightningElement {
    //FIELD PARAMS
    @api dirty;
    @api disabled;
    @api fieldName;
    @api readOnly;
    @api required;
    @api value;
    @api variant;

    //OBJECT PARAMS
    @api density;
    @api objectApiName;
    @api recordId;
    @api recordTypeId;

    @wire(MessageContext)
    messageContext;

    onChange(event) {
        this.value = event.detail.value;
        const payload = { name: this.fieldName, value: this.value };
        publish(this.messageContext, nksSingleValueUpdate, payload);
    }
}