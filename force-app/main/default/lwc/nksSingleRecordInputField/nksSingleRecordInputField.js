import { LightningElement, api, wire } from 'lwc';
import nksSingleValueUpdate from '@salesforce/messageChannel/nksSingleValueUpdate__c';
import { getRecordCreateDefaults, getFieldValue } from 'lightning/uiRecordApi';
import { publish, MessageContext } from 'lightning/messageService';

export default class NksSingleRecordInputField extends LightningElement {
    //FIELD PARAMS
    @api dirty;
    @api disabled;
    @api fieldName;
    @api readOnly;
    @api required;
    @api value = null;
    @api variant;

    //OBJECT PARAMS
    @api density;
    @api objectApiName;
    @api recordId;
    @api recordTypeId;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        const payload = { name: this.fieldName, value: this.value };
        publish(this.messageContext, nksSingleValueUpdate, payload);
    }

    // @wire(getRecordCreateDefaults, { objectApiName: '$objectApiName', recordTypeId: '$recordTypeId' })
    // setRecordCreateDefaults({ data, error }) {
    //     if (data) {
    //         let defaultValue = getFieldValue(data.record, this.fieldName);

    //         const payload = { name: this.fieldName, value: defaultValue };
    //         publish(this.messageContext, nksSingleValueUpdate, payload);
    //     }

    // }

    onChange(event) {
        this.value = event.detail.value;
        const payload = { name: this.fieldName, value: this.value };
        publish(this.messageContext, nksSingleValueUpdate, payload);
    }
}