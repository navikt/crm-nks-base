import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class nksFlowRedirectToRecord extends NavigationMixin(LightningElement) {
    @api recordId;
    hasNavigated = false;

    @api invoke() {
        console.log(
            'nksFlowRedirectToRecord: invoke() called. RecordId: ',
            this.recordId + ', hasNavigated: ' + this.hasNavigated
        );
        // Prevent multiple navigations
        if (this.hasNavigated) {
            console.warn('nksFlowRedirectToRecord: Navigation already performed, skipping');
            return;
        }

        this.performRedirect();
    }

    performRedirect() {
        if (this.recordId && !this.hasNavigated) {
            console.log('nksFlowRedirectToRecord: Performing navigation to recordId:', this.recordId);

            this.hasNavigated = true;

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            });
        } else if (!this.recordId) {
            console.error('nksFlowRedirectToRecord: No recordId provided');
        }
    }
}
