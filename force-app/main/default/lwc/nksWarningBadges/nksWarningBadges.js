import { LightningElement, api, track } from 'lwc';
import getBadges from '@salesforce/apex/NKS_WarningBadgeController.getBadges';

export default class NksWarningBadges extends LightningElement {
    @api recordId;
    @api componentTitle;
    @track badges;
    @api objectApiName;

    connectedCallback() {
        this.getList();
    }

    get title() {
        const numRecords = this.relatedRecords ? this.relatedRecords.length : 0;
        return ' ' + numRecords + ' ' + this.componentTitle;
    }

    getList() {
        getBadges({
            parentId: this.recordId,
            parentObjectApiName: this.objectApiName
        })
            .then((data) => {
                this.badges = data && data.length > 0 ? data : null;
            })
            .catch((error) => {
                console.log(
                    'An error occurred: ' + JSON.stringify(error, null, 2)
                );
            });
    }
}
