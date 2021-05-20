import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class NksFlowRecordNavigator extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    connectedCallback() {
        this.navigateToSObject();
        this.fireFlowFinish();
    }

    fireFlowFinish() {
        // navigate to the next screen
        const finishEvent = new FlowNavigationFinishEvent();
        this.dispatchEvent(finishEvent);
    }

    navigateToSObject() {
        // Navigate to the Account home page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: this.objectApiName,
                actionName: 'view'
            }
        });
    }
}
