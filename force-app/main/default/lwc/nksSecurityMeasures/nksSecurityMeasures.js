import { LightningElement, api, track } from 'lwc';
import getSecurityMeasures from '@salesforce/apex/NKS_SecurityMeasuresController.getSecurityMeasures';

export default class nksSecurityMeasures extends LightningElement {
    @api recordId;
    @api componentTitle;
    @track relatedRecords;
    @api objectApiName;

    get title() {
        const numRecords = this.relatedRecords ? this.relatedRecords.length : 0;
        return ' ' + numRecords + ' ' + this.componentTitle;
    }

    handleClick() {
        var x = this.template.querySelector('[data-id="modal"]');
        if (x.style.display != "block") {
            x.style.display = "block";
        } else {
            x.style.display = "none";
        }
    }

    connectedCallback() {
        this.getList();
    }

    getList() {
        getSecurityMeasures({
            parentId: this.recordId,
            parentObjectApiName: this.objectApiName
        })
            .then(data => {
                this.relatedRecords = (data && data.length > 0) ? data : null;
            })
            .catch(error => {
                console.log('An error occurred: ' + JSON.stringify(error, null, 2));
            });
    }

}
