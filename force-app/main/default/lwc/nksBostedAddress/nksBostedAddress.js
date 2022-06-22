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

    /*get addressLine1() {
        var line = '';
        //this.addList = this.boAddresses[0];
        //for (var n = 0; n < this.boAddresses.length; n++) {
        /*if (this.addList.adressenavn != null) line += this.addList.adressenavn;
        if (this.addList.husnummer != null) line += ' ' + this.addList.husnummer;

        if (this.boAddresses.adressenavn != null) line += this.boAddresses.adressenavn;
        if (this.boAddresses.husnummer != null) line += ' ' + this.boAddresses.husnummer;
        if (this.boAddresses.husbokstav != null) line += ' ' + this.boAddresses.husbokstav;
        if (this.boAddresses.bruksenhetsnummer != null) line += ' ' + this.boAddresses.bruksenhetsnummer;

        return line;
    }*/

    /*get addressLine1() {
        var line = '';
        this.addList = this.boAddresses;
        if (this.addList != null && this.addList.length > 0) {
            for (var n = 0; n < this.addList.length; n++) {
                this.adressenavn = this.addList[n].adressenavn;
                this.husnummer = this.addList[n].husnummer;
                this.husbokstav = this.addList[n].husbokstav;
                this.bruksenhetsnummer = this.addList[n].bruksenhetsnummer;
                if (this.adressenavn != null) {
                    line += this.adressenavn;
                }
                if (this.husnummer != null) line += ' ' + this.husnummer;
            }
        }
        return line;
    }*/

    get addressLine() {
        return 'Address Line 1';
    }
}
