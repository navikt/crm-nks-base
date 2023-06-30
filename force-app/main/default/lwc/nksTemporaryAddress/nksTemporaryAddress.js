import { LightningElement, api, wire } from 'lwc';
import getTemporaryAddresses from '@salesforce/apex/NKS_TemporaryAddressController.getTemporaryAddresses';

export default class NksBostedAddress extends LightningElement {
    @api objectApiName;
    @api recordId;
    temporaryAddresses = [];
    open = false;

    @wire(getTemporaryAddresses, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredAddresses({ error, data }) {
        if (data) {
            console.log('pppp:' + JSON.stringify(data));
            this.temporaryAddresses = data;
        }
        if (error) {
            this.addError(error);
        }
    }

    get iconName() {
        return this.open ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get hasRecord() {
        return this.temporaryAddresses.length > 0;
    }

    onclickHandler() {
        this.open = !this.open;
    }
}
