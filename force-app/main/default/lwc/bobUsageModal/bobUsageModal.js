import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import bobLogo from '@salesforce/resourceUrl/bobLogo';
import { createRecord } from 'lightning/uiRecordApi';
import REPORTING_OBJECT from '@salesforce/schema/ReportingData__c';
import CRM_CATEGORY_FIELD from '@salesforce/schema/ReportingData__c.CRM_Category__c';
import NKS_RELATED_FIELD from '@salesforce/schema/ReportingData__c.NKS_Related_Record__c';

export default class BobUsageModal extends LightningModal {
    @api recordId;
    bobLogo = bobLogo;

    connectedCallback() {
        console.log('BobUsageModal opened for recordId:', this.recordId);
    }

    handleButtonClick(event) {
        if (event.target.dataset.answer === 'yes') {
            const fields = {};
            fields[CRM_CATEGORY_FIELD.fieldApiName] = 'Besvart med Bob';
            fields[NKS_RELATED_FIELD.fieldApiName] = this.recordId;
            const recordInput = { apiName: REPORTING_OBJECT.objectApiName, fields };
            createRecord(recordInput).catch((error) => {
                this.close();
                console.error('Error creating ReportingData__c record:', error);
            });
        }
        this.close();
    }
}
