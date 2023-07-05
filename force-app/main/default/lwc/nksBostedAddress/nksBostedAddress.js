import { LightningElement, api, wire, track } from 'lwc';
import getResidentialAddress from '@salesforce/apex/NKS_BostedAddressController.getBostedAddress';

export default class NksBostedAddress extends LightningElement {
    @api objectApiName;
    @api recordId;
    @track sectionClass = 'slds-section section';
    @track sectionIconName = 'utility:chevronright';
    residentialAddresses = [];
    isExpanded = false;
    ariaHidden = true;

    @wire(getResidentialAddress, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredAddresses({ error, data }) {
        if (data) {
            this.residentialAddresses = data;
        }
        if (error) {
            console.log('Problem getting residentialAddress: ' + error);
        }
    }

    get iconName() {
        return this.open ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get hasRecords() {
        return this.residentialAddresses.length > 0;
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
