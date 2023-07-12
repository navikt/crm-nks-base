import { LightningElement, api, wire, track } from 'lwc';
import getTemporaryAddresses from '@salesforce/apex/NKS_AddressController.getTemporaryAddresses';

export default class NksBostedAddress extends LightningElement {
    @api objectApiName;
    @api recordId;
    @track sectionClass = 'slds-section section';
    @track sectionIconName = 'utility:chevronright';
    _temporaryAddresses = [];
    isExpanded = false;
    ariaHidden = true;

    @wire(getTemporaryAddresses, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredAddresses({ error, data }) {
        if (data) {
            this._temporaryAddresses = data;
        }
        if (error) {
            console.log('Problem getting temporaryAddress: ' + error);
        }
    }

    get temporaryAddresses() {
        let addressesToReturn = [];
        if (this._temporaryAddresses.length > 0) {
            this._temporaryAddresses.forEach((element) => {
                if (element.fullName) {
                    addressesToReturn.push(element.fullName);
                }
                let addressLine = '';
                if (element.address) {
                    addressLine += element.address;
                }
                if (element.houseNumber) {
                    addressLine += ' ' + element.houseNumber;
                }
                if (element.houseLetter) {
                    addressLine += element.houseLetter;
                }
                addressesToReturn.push(addressLine);
                let postInfo = '';
                if (element.zipCode) {
                    postInfo += element.zipCode;
                }
                if (element.city) {
                    postInfo += ' ' + element.city;
                }
                addressesToReturn.push(postInfo);
                let region = '';
                if (element.region) {
                    region += element.region;
                }
                if (element.countryCode) {
                    region += ' ' + element.countryCode;
                }
                if (region !== '') {
                    addressesToReturn.push(region);
                } else {
                    addressesToReturn.push('NORGE NO');
                }
            });
        }
        return addressesToReturn.join('\n');
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
