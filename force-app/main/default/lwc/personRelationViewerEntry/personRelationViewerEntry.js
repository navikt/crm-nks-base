import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";

export default class PersonRelationViewerEntry extends NavigationMixin(LightningElement) {

    @api relation;
    recordPageUrl;

    navigateToSObject(event) {
        event.preventDefault();
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.relation.accountId,
                actionName: 'view',
            },
        });
    }

    connectedCallback() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.relation.accountId,
                actionName: 'view',
            },
        }).then(url => {
            this.recordPageUrl = url;
        });
    }

}