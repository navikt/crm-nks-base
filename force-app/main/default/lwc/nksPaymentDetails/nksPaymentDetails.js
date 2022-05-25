import { LightningElement, api } from 'lwc';

export default class NksPaymentDetails extends LightningElement {
    @api ytelse;
    @api displayHeader;
    @api labels;

    get grossPayment() {
        let grossPayment;

        if (this.ytelse) {
            grossPayment = this.ytelse.ytelseNettobeloep - this.totalDeductions;
        }

        return grossPayment;
    }

    get totalDeductions() {
        let totalDeductions;

        if (this.ytelse) {
            totalDeductions = this.ytelse.trekksum + this.ytelse.skattsum;
        }

        return totalDeductions;
    }
}
