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
    krrFields = 'INT_KrrEmail__c, INT_KrrMobilePhone__c, INT_KRR_Reservation__c, INT_VerifisertFromKRR__c';
    updated = false;

    get recordCmp() {
        return this.template.querySelector('c-nks-record-info');
    }

    handleDataLoaded(event) {
        let personIdent = event.detail.Name.value;
        if (this.updated === false && personIdent && personIdent != '') {
            this.initiateKrrUpdate(personIdent);
        }
    }

    initiateKrrUpdate(personIdent) {
        this.isLoading = true;
        //Get ident from record info component
        updateKrrInfo({ personIdent: personIdent })
            .then((result) => {
                //Successful update
                this.refreshRecord();
            })
            .catch((error) => {
                //Update failed
                console.log(JSON.stringify(error, null, 2));
            })
            .finally(() => {
                this.isLoading = false;
                this.updated = true; //Preventing loop when child fires another event after refresh
            });
    }

    refreshRecord() {
        //Calls the child component to be refreshed after updating KRR information
        this.recordCmp.refreshRecord();
    }
}
