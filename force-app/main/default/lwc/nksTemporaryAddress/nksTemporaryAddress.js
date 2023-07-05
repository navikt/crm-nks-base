import { LightningElement, api, wire, track } from 'lwc';
import getTemporaryAddresses from '@salesforce/apex/NKS_TemporaryAddressController.getTemporaryAddresses';

export default class NksBostedAddress extends LightningElement {
    @api objectApiName;
    @api recordId;
    @track sectionClass = 'slds-section section';
    @track sectionIconName = 'utility:chevronright';
    temporaryAddresses = [];
    isExpanded = false;
    ariaHidden = true;

    @wire(getTemporaryAddresses, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredAddresses({ error, data }) {
        if (data) {
            this.temporaryAddresses = data;
        }
        if (error) {
            this.addError(error);
        }
    }

    get iconName() {
        return this.open ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get hasRecords() {
        return this.temporaryAddresses.length > 0;
    }

    /* Function to handle open/close section */
    handleOpen() {
        if (this.sectionClass === 'slds-section section slds-is-open') {
            this.sectionClass = 'slds-section section';
            this.sectionIconName = 'utility:chevronright';
            this.isExpanded = false;
            this.ariaHidden = true;
        } else {
            this.sectionClass = 'slds-section section slds-is-open';
            this.sectionIconName = 'utility:chevrondown';
            this.isExpanded = true;
            this.ariaHidden = false;
        }
    }
}
