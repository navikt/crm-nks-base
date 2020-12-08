import { LightningElement, api, track } from 'lwc';

export default class NksNavUnitContactInformation extends LightningElement {
    @api numCols = 2;
    @track _contactInformation;
    @track _visitorLocations = [];
    _visitorLocationsLength = 0;
    hasContactInformation = false;
    hasVisitorLocations = false;

    @api
    set contactInformation(value) {
        if (value) {
            this._contactInformation = value;
            this.hasContactInformation = true;

            if (value.publikumsmottak && value.publikumsmottak.length) {
                hasVisitorLocations = true;
                this._visitorLocations = value.publikumsmottak;
                this._visitorLocationsLength = value.publikumsmottak.length;
            }
        }
    }

    get columnWidth() { return 12 / this.numCols; }

    //get hasContactInformation() { return this._contactInformation ? true : false; }
    get contactInformation() { return this._contactInformation; }

    //get hasVisitorLocations() { return 0 < this._visitorLocationsLength; }
    get visitorLocations() { return this._visitorLocations; }

    get postalAddress() { return this.contactInformation.postadresse ? this.contactInformation.postadresse.concatenatedAddress : ''; }

    get visitingAddress() { return this.contactInformation.besoeksadresse ? this.contactInformation.besoeksadresse.concatenatedAddress : ''; }
}