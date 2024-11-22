import { LightningElement, api, wire, track } from 'lwc';
import getOppholdsAddress from '@salesforce/apex/NKS_AddressController.getOppholdsAddress';
import nksTemporaryAddressHTML from './nksTemporaryAddress.html';
import nksTemporaryAddressV2HTML from './nksTemporaryAddressV2.html';

export default class NksBostedAddress extends LightningElement {
    @api objectApiName;
    @api recordId;
    @api useNewDesign;
    @api pdlLastUpdatedFormatted;
    @track sectionClass = 'slds-section section';
    @track sectionIconName = 'utility:chevronright';
    _temporaryAddresses = [];
    isExpanded = false;
    ariaHidden = true;

    render() {
        return this.useNewDesign ? nksTemporaryAddressV2HTML : nksTemporaryAddressHTML;
    }

    @wire(getOppholdsAddress, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredAddresses({ error, data }) {
        if (data) {
            this._temporaryAddresses = data;
        }
        if (error) {
            this._temporaryAddresses.push('Feil under henting av oppholdsadresse.');
            console.error('Problem getting temporaryAddress: ' + error);
        }
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

    handleCopy(event) {
        const hiddenInput = document.createElement('input');
        const eventValue = event.currentTarget.value;
        hiddenInput.value = eventValue;
        document.body.appendChild(hiddenInput);
        hiddenInput.focus();
        hiddenInput.select();
        // eslint-disable-next-line @locker/locker/distorted-document-exec-command
        document.execCommand('copy');
        document.body.removeChild(hiddenInput);
        event.currentTarget.focus();
    }

    get temporaryAddresses() {
        const addressesToReturn = this._temporaryAddresses.map((element) => {
            const fullName = element.fullName ? element.fullName : '';
            const addressLine = [
                element.address ? element.address : '',
                element.houseNumber ? ' ' + element.houseNumber : '',
                element.houseLetter ? ' ' + element.houseLetter : ''
            ]
                .join('')
                .trim();
            const postInfo = [element.zipCode ? element.zipCode : '', element.city ? ' ' + element.city : '']
                .join('')
                .trim();
            const region = [element.region ? element.region : '', element.countryCode ? ' ' + element.countryCode : '']
                .join('')
                .trim();

            return [fullName, addressLine, postInfo, region || 'NORGE NO'].join('\n').trim();
        });
        return addressesToReturn.join('\n\n').trim();
    }

    get temporaryAddressesNewDesign() {
        if (this._temporaryAddresses.length === 0) {
            return [];
        }
        this.showCopyButton = true;
        const addressesToReturn = this._temporaryAddresses.map((element) => {
            const type = element.type ? element.type[0] + element.type.slice(1).toLowerCase() + ':' : '';
            const fullName = element.fullName
                ? element.fullName
                      .split(' ')
                      .map((name) => name[0].toUpperCase() + name.slice(1).toLowerCase())
                      .join(' ')
                : '';
            const addressLine = [
                element.address ? element.address[0] + element.address.slice(1).toLowerCase() : '',
                element.houseNumber ? ' ' + element.houseNumber : '',
                element.houseLetter ? ' ' + element.houseLetter : ''
            ]
                .join('')
                .trim();
            const postInfo = [
                element.zipCode ? element.zipCode : '',
                element.city ? ' ' + element.city[0] + element.city.slice(1).toLowerCase() : ''
            ]
                .join('')
                .trim();
            const region = [
                element.region ? element.region[0] + element.region.slice(1).toLowerCase() : '',
                element.countryCode ? ' ' + element.countryCode : ''
            ]
                .join('')
                .trim();

            const typeAndFullName = [type, fullName].filter(Boolean).join(' ');
            const otherParts = [addressLine, postInfo, region || 'Norge NO'].filter(Boolean).join(', ');

            return [typeAndFullName, otherParts].filter(Boolean).join(', ');
        });
        return addressesToReturn;
    }

    get hasRecords() {
        return this.temporaryAddresses.length > 0;
    }
}
