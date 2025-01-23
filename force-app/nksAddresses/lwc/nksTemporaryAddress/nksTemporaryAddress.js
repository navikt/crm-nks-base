import { LightningElement, api, wire, track } from 'lwc';
import getOppholdsAddress from '@salesforce/apex/NKS_AddressController.getOppholdsAddress';
import nksTemporaryAddressHTML from './nksTemporaryAddress.html';
import nksTemporaryAddressV2HTML from './nksTemporaryAddressV2.html';
import { handleAddressCopy } from 'c/nksComponentsUtils';

export default class NksBostedAddress extends LightningElement {
    @api objectApiName;
    @api recordId;
    @api useNewDesign;
    @api pdlLastUpdatedFormatted;
    @api county;
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
        handleAddressCopy(event);
    }

    capitalizeWords(str) {
        return str
            ? str
                  .split(' ')
                  .filter((word) => word)
                  .map((word) => word[0].toUpperCase() + word.slice(1).toLowerCase())
                  .join(' ')
            : '';
    }

    formatAddressComponent(component) {
        return component ? component[0].toUpperCase() + component.slice(1).toLowerCase() : '';
    }

    buildAddressLine(address, houseNumber, houseLetter) {
        return [
            this.formatAddressComponent(address),
            houseNumber ? ` ${houseNumber}` : '',
            houseLetter ? ` ${houseLetter}` : ''
        ]
            .join('')
            .trim();
    }

    buildPostInfo(zipCode, city) {
        return [zipCode || '', city ? ` ${this.formatAddressComponent(city)}` : ''].join('').trim();
    }

    buildRegion(region, countryCode) {
        return [this.formatAddressComponent(region), countryCode ? ` ${countryCode}` : ''].join('').trim();
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

        return this._temporaryAddresses.map((element) => {
            const type = element.type ? `${element.type[0].toUpperCase()}${element.type.slice(1).toLowerCase()}:` : '';
            const fullName = this.capitalizeWords(element.fullName);
            const addressLine = this.buildAddressLine(element.address, element.houseNumber, element.houseLetter);
            const postInfo = this.buildPostInfo(element.zipCode, element.city);
            const region = this.buildRegion(element.region, element.countryCode);
            const typeAndFullName = [type, fullName].filter(Boolean).join(' ');
            const otherParts = [addressLine, postInfo, this.county || region || 'Norge NO'].filter(Boolean).join(', ');

            return [typeAndFullName, otherParts].filter(Boolean).join(', ');
        });
    }

    get hasRecords() {
        return this.temporaryAddresses.length > 0;
    }
}
