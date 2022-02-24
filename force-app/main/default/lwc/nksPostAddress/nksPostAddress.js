import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getPostAddress from '@salesforce/apex/NKS_PostAddressController.getPostAddress';

export default class NksPostAddress extends LightningElement {
    open = false;
    showbutton = false;
    addressString;
    get iconName(){
        return this.open ? 'utility:chevrondown' : 'utility:chevronright';
    }
    get address(){
        if(!this._address.data || this._address.data.status !== '200'){
            this._address = refreshApex(this._address);
        }
        switch (this._address.data.status){
            case '200':
                if (!this.addressString) 
                    this.addressString = this.formattedAddress();
                    this.showbutton = true;
                console.log(this.addressString);
                return this.addressString;
            case '400':
                return 'Ugyldig input.';
            case '401':
                return 'Ingen tilgang til postadresse tjenesten.';
            case '404':
                return 'Person / organisasjon har ukjent adresse.';
            case '410':
                return 'Person er død og har ukjent adresse.';
            case '500':
                return 'Intern teknisk feil i postadresse tjenesten.';
        }
        return 'Feil henting postadresse.';
    }
    formattedAddress(){
        if(this._address.data.type === 'NorskPostadresse') return this.formattedNorwegianAddress();
        if(this._address.data.type === 'UtenlandskPostadresse') return this.formattedForeignAddress();
        return 'Ukjent adressetype.'
    }
    formattedNorwegianAddress(){
        let addr = [];
        if(this._address.data.navn && this._address.data.navn.length > 0) addr.push(this._address.data.navn);
        if(this._address.data.adresselinje1 && this._address.data.adresselinje1.length > 0) addr.push(this._address.data.adresselinje1);
        if(this._address.data.adresselinje2 && this._address.data.adresselinje2.length > 0) addr.push(this._address.data.adresselinje2);
        if(this._address.data.adresselinje3 && this._address.data.adresselinje3.length > 0) addr.push(this._address.data.adresselinje3);
        let zipAndPlace = [];
        if(this._address.data.postummer && this._address.data.postummer.length > 0) zipAndPlace.push(this._address.data.postummer);
        if(this._address.data.poststed && this._address.data.poststed.length > 0) zipAndPlace.push(this._address.data.poststed);
        if(zipAndPlace.length > 0) addr.push(zipAndPlace.join(' '));
        let countryAndCode = [];
        if(this._address.data.land && this._address.data.land.length > 0) countryAndCode.push(this._address.data.land);
        if(this._address.data.landkode && this._address.data.landkode.length > 0) countryAndCode.push(this._address.data.landkode);
        if(countryAndCode.length > 0) addr.push(countryAndCode.join(' '));
        return addr.join('\n');
    }
    formattedForeignAddress(){
        let addr = [];
        if(this._address.data.navn && this._address.data.navn.length > 0) addr.push(this._address.data.navn);
        if(this._address.data.adresselinje1 && this._address.data.adresselinje1.length > 0) addr.push(this._address.data.adresselinje1);
        if(this._address.data.adresselinje2 && this._address.data.adresselinje2.length > 0) addr.push(this._address.data.adresselinje2);
        if(this._address.data.adresselinje3 && this._address.data.adresselinje3.length > 0) addr.push(this._address.data.adresselinje3);
        let countryAndCode = [];
        if(this._address.data.land && this._address.data.land.length > 0) countryAndCode.push(this._address.data.land);
        if(this._address.data.landkode && this._address.data.landkode.length > 0) countryAndCode.push(this._address.data.landkode);
        if(countryAndCode.length > 0) addr.push(countryAndCode.join(' '));
        return addr.join('\n');
    }
    onclickHandler(){
        this.open = !this.open;
    }
    copyHandler(){
        let clipboardInput = this.template.querySelector(".clipboardInput");
        clipboardInput.disabled = false;
        clipboardInput.hidden = false;
        clipboardInput.value = this.addressString;
        clipboardInput.select();
        console.log(document.execCommand("copy"));
        clipboardInput.hidden = true;
        clipboardInput.disabled = true;
    }
    @wire(getPostAddress) _address;
}
