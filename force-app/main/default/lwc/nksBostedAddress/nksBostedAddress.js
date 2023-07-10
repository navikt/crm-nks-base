import { LightningElement, api, wire, track } from 'lwc';
import getResidentialAddress from '@salesforce/apex/NKS_BostedAddressController.getBostedAddress';
export default class NksBostedAddress extends LightningElement {
    @api objectApiName;
    @api recordId;
    @track sectionClass = 'slds-section section';
    @track sectionIconName = 'utility:chevronright';
    _residentialAddresses = [];
    isExpanded = false;
    ariaHidden = true;
    showbutton = false;

    @wire(getResidentialAddress, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredAddresses({ error, data }) {
        if (data) {
            this._residentialAddresses = data;
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

    get residentialAddresses() {
        let addressesToReturn = [];
        if (this._residentialAddresses.length > 0) {
            this.showbutton = true;
            this._residentialAddresses.forEach((element) => {
                if (element.fulltNavn) {
                    addressesToReturn.push(element.fulltNavn);
                }
                let addressLine = '';
                if (element.adressenavn) {
                    addressLine += element.adressenavn;
                }
                if (element.husnummer) {
                    addressLine += ' ' + element.husnummer;
                }
                if (element.husbokstav) {
                    addressLine += element.husbokstav;
                }
                addressesToReturn.push(addressLine);
                let postInfo = '';
                if (element.postnummer) {
                    postInfo += element.postnummer;
                }
                if (element.poststed) {
                    postInfo += ' ' + element.poststed;
                }
                addressesToReturn.push(postInfo);
                let region = '';
                if (element.region) {
                    region += element.region;
                }
                if (element.landkode) {
                    region += ' ' + element.landkode;
                }
                if (region !== '') {
                    addressesToReturn.push(region);
                } else {
                    addressesToReturn.push('NORGE NO\n\n');
                }
            });
        }
        return addressesToReturn.join('\n');
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

    copyHandler() {
        let clipboardInput = this.template.querySelector('.clipboardInput');
        clipboardInput.disabled = false;
        clipboardInput.hidden = false;
        clipboardInput.value = this.residentialAddresses;
        clipboardInput.select();
        document.execCommand('copy');
        clipboardInput.hidden = true;
        clipboardInput.disabled = true;
    }
}
