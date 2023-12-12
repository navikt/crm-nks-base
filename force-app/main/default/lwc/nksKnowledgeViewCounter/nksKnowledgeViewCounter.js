import { LightningElement, api, wire } from 'lwc';
import countViews from '@salesforce/apex/NKS_AuditLogController.countViews';
import isKnowledgeUser from '@salesforce/apex/NKS_AuditLogController.isKnowledgeUser';

export default class NksKnowledgeViewCounter extends LightningElement {
    @api recordId;
    siteURL;
    numOfViews = 0;
    hasPermission = false;

    connectedCallback() {
        this.siteURL = '/apex/Audit_Log_Knowledge?Id=' + this.recordId;
    }

    @wire(isKnowledgeUser)
    wiredRes({ error, data }) {
        if (error) {
            console.log(error);
        } else if (data) {
            this.hasPermission = data;
        }
    }

    @wire(countViews, {
        recordId: '$recordId',
        lookupField: 'Knowledge__c'
    })
    wiredCountViews({ data, error }) {
        if (data) {
            this.numOfViews = data;
        } else if (error) {
            console.log(error);
        }
    }
}
