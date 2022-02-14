import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class nksReadyResponseListEntry extends NavigationMixin(LightningElement) {
    @api record;

    connectedCallback() {
        this.navigateToRecord;
    }

    navigateToRecord(event) {
        event.preventDefault();
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.Id,
                actionName: 'view'
            }
        });
    }
}
