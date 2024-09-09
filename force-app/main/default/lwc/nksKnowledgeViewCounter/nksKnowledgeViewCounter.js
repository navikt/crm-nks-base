import { LightningElement, api, wire } from 'lwc';
import createAuditLog from '@salesforce/apex/NKS_AuditLogController.createAuditLog';
import countViews from '@salesforce/apex/NKS_AuditLogController.countViews';
import isKnowledgeUser from '@salesforce/apex/NKS_AuditLogController.isKnowledgeUser';

export default class NksKnowledgeViewCounter extends LightningElement {
    @api recordId;
    numOfViews = 0;
    hasPermission = false;
    isRendered = false;

    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            createAuditLog({ recordId: this.recordId, lookupField: 'Knowledge__c' });
        }
    }

    @wire(isKnowledgeUser)
    wiredIsKnowledgeUser({ error, data }) {
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
