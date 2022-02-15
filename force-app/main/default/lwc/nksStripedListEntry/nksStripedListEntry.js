import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class nksStripedListEntry extends NavigationMixin(LightningElement) {
    @api record;
    @api index;

    recordPageUrl;

    get className() {
        return this.index % 2 == 0
            ? 'slds-grid slds-var-p-horizontal_medium slds-var-p-vertical_x-small listItem isEven'
            : 'slds-grid slds-var-p-horizontal_medium slds-var-p-vertical_x-small listItem';
    }

    navigateToSObject(event) {
        event.preventDefault();
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.recordId,
                actionName: 'view'
            }
        });
    }

    connectedCallback() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.recordId,
                actionName: 'view'
            }
        }).then((url) => {
            this.recordPageUrl = url;
        });
    }
}
