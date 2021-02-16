import { LightningElement, api } from 'lwc';

export default class NksNavUnitVisitorLocation extends LightningElement {
    @api location;

    get visitingAddress() {
        return this.location.besoeksadresse.concatenatedAddress;
    }

    get locationName() {
        if (this.location.stedsbeskrivelse) {
            return this.location.stedsbeskrivelse;
        }

        return null;
    }

    get hasOpeningHours() {
        let a =
            this.location.aapningstider &&
            0 < this.location.aapningstider.length;
        return (
            this.location.aapningstider &&
            0 < this.location.aapningstider.length
        );
    }

    get openingHours() {
        return this.location.aapningstider;
    }
}
