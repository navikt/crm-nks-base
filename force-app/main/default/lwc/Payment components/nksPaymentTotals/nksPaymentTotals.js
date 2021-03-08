import { LightningElement, api } from 'lwc';

export default class NksPaymentTotals extends LightningElement {
    @api paymentGroups;

    connectedCallback() {}

    get totalNetAmount() {
        let total = 0;
        if (this.paymentGroups) {
            this.paymentGroups.forEach((paymentGroup) => {
                if (paymentGroup) {
                    paymentGroup.forEach((payment) => {
                        total += payment.data.utbetalingNettobeloep;
                    });
                }
            });
        }
        return total;
    }

    //Deductions are defined with a negative value
    get totalDeductions() {
        let total = 0;
        if (this.paymentGroups) {
            this.paymentGroups.forEach((paymentGroup) => {
                if (paymentGroup) {
                    paymentGroup.forEach((payment) => {
                        payment.data.ytelseListe.forEach((ytelse) => {
                            total += ytelse.trekksum;
                            total += ytelse.skattsum;
                        });
                    });
                }
            });
        }
        return total;
    }

    get totalPaymentAmount() {
        return this.totalNetAmount - this.totalDeductions;
    }
}
