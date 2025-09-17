import { LightningElement, api, wire } from 'lwc';
import getResidentialAddress from '@salesforce/apex/NKS_AddressController.getBostedAddress';
import { handleAddressCopy } from 'c/nksComponentsUtils';
export default class NksBostedAddress extends LightningElement {
    @api objectApiName;
    @api recordId;
    @api useNewDesign;
    @api pdlLastUpdatedFormatted;
    @api county;

   sectionClass = 'slds-section section';
    sectionIconName = 'utility:chevronright';
    _residentialAddresses = [];
    isExpanded = false;
    ariaHidden = true;
    showCopyButton = false;

    @wire(getResidentialAddress, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredAddresses({ error, data }) {
        if (data) {
            this._residentialAddresses = data;
        }
        if (error) {
            this._residentialAddresses.push('Feil under henting av bostedsadresse.');
            console.error('Problem getting residentialAddress: ' + error);
        }
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

    get residentialAddresses() {
        if (this._residentialAddresses.length === 0) {
            return [];
        }

        this.showCopyButton = true;
        const addressesToReturn = this._residentialAddresses.map((element) => {
            const type = element.type ? 'Type: ' + element.type : '';
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

            return [type, fullName, addressLine, postInfo, region || 'NORGE NO'].join('\n').trim();
        });
        return addressesToReturn.join('\n\n').trim();
    }

    get residentialAddressesNewDesign() {
        if (this._residentialAddresses.length === 0) {
            return [];
        }

        this.showCopyButton = true;

        return this._residentialAddresses.map((element) => {
            const type = element.type ? `${element.type[0].toUpperCase()}${element.type.slice(1).toLowerCase()}:` : '';
            const fullName = this.capitalizeWords(element.fullName);
            const addressLine = this.buildAddressLine(element.address, element.houseNumber, element.houseLetter);
            const postInfo = this.buildPostInfo(element.zipCode, element.city);
            const region = this.buildRegion(element.region, element.countryCode);
            const typeAndFullName = [type, fullName].filter(Boolean).join(' ');
            const otherParts = [addressLine, postInfo, region || 'Norge NO'].filter(Boolean).join(', ');

            return [typeAndFullName, otherParts].filter(Boolean).join(', ');
        });
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
        // eslint-disable-next-line @locker/locker/distorted-document-exec-command
        document.execCommand('copy');
        clipboardInput.hidden = true;
        clipboardInput.disabled = true;
    }

    handleCopy(event) {
        handleAddressCopy(event);
    }
}
