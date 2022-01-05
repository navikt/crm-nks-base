import { LightningElement, api, wire } from 'lwc';
import crmSingleValueUpdate from '@salesforce/messageChannel/crmSingleValueUpdate__c';
import { publish, MessageContext } from 'lightning/messageService';

//#### LABEL IMPORTS ####
import VALIDATION_ERROR from '@salesforce/label/c.NKS_Single_Record_Input_Validation_Error';

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
        publish(this.messageContext, crmSingleValueUpdate, payload);
    }

    onChange(event) {
        this.value = event.detail.value;
        const payload = { name: this.fieldName, value: this.value };
        publish(this.messageContext, crmSingleValueUpdate, payload);
    }

    //Validation preventing user moving to next screen in flow if state is not valid
    @api
    validate() {
        //Theme and theme group must be set
        if (true === this.required && this.value) {
            return { isValid: true };
        } else {
            return {
                isValid: false,
                errorMessage: VALIDATION_ERROR
            };
        }
    }
}
