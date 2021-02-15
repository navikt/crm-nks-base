import { LightningElement, api } from 'lwc';
import updateKrrInfo from '@salesforce/apex/NKS_KrrInformationController.updateKrrInformation';

export default class NksKrrInformation extends LightningElement {
    @api recordId; // Value from UiRecordAPI
    @api objectApiName; // Value from UiRecordAPI
    @api relationshipField;
    @api iconName;
    @api cardLabel;
    @api numCols;
    isLoading = false;
    krrFields =
        'INT_KrrEmail__c, INT_KrrMobilePhone__c, INT_KRR_Reservation__c, INT_LastUpdatedFromKRR__c';

    get recordCmp() {
        return this.template.querySelector('c-nks-record-info');
    }

    handleDataLoaded(event) {
        this.initiateKrrUpdate();
    }

    initiateKrrUpdate() {
        this.isLoading = true;
        //Get ident from record info component
        updateKrrInfo({ personIdent: this.recordCmp.viewedRecordId })
            .then((result) => {
                //Successful update
                this.refreshRecord();
            })
            .catch((error) => {
                //Update failed
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    refreshRecord() {
        //Calls the child component to be refreshed after updating KRR information
        this.recordCmp.refreshRecord();
    }
}
