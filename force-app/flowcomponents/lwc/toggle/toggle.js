import { LightningElement, track, api, wire } from 'lwc';
import nksSingleValueUpdate from '@salesforce/messageChannel/nksSingleValueUpdate__c';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { publish, MessageContext } from 'lightning/messageService';

export default class Toggle extends LightningElement {
    @track checked = false;
    @api label;

    @wire(MessageContext)
    messageContext;

    get togglechecked() {
        return this._togglechecked;
    }

    @api
    set togglechecked(value) {
        this._togglechecked = value;
    }

    handleChange() {
        this.checked = !this.checked;
        const attributeChangeEvent = new FlowAttributeChangeEvent('togglechecked', this.checked);
        this.dispatchEvent(attributeChangeEvent);
        this.publishFieldChange('createtask', this.checked);
    }

    publishFieldChange(field, value) {
        const payload = { name: field, value: value };
        publish(this.messageContext, nksSingleValueUpdate, payload);
    }
}
