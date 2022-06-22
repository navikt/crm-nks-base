import { LightningElement, api, wire } from 'lwc';
import getBostedAddress from '@salesforce/apex/NKS_BostedAddressController.getBostedAddress';

export default class NksBostedAddress extends LightningElement {
    @api objectApiName;
    @api recordId;
    boAddresses;
    addList;
    adressenavn;
    husnummer;
    husbokstav;
    bruksenhetsnummer;
    endringDato;

    @wire(getBostedAddress, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredAddresses({ error, data }) {
        if (data) {
            console.log('pppp:' + JSON.stringify(data));
            this.boAddresses = data;
        }
        if (error) {
            this.addError(error);
        }
    }
}
