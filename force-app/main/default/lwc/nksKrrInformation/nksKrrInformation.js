import { LightningElement, api } from 'lwc';

export default class NksKrrInformation extends LightningElement {
    @api recordId; // Value from UiRecordAPI
    @api objectApiName; // Value from UiRecordAPI
    @api relationshipField;
    @api iconName;
    @api cardLabel;
    krrFields =
        'INT_KRR_Reservation, INT_KrrEmail__c, INT_KrrMobilePhone__c, INT_LastUpdatedFromKRR__c';

    handleDataLoaded(event) {
        console.log('LOADED');
    }

    refreshRecord() {
        //Calls the child component to be refreshed after updating KRR information
        let recordCmp = this.template.querySelector('c-nks-record-info');
        recordCmp.refreshRecord();
    }
}
