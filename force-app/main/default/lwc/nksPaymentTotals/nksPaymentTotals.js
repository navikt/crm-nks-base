import { LightningElement, api } from 'lwc';

class YtelseTotal {
    constructor(ytelse, totals) {
        this.ytelse = ytelse;
        this.totals = totals;
    }
}

class Totals {
    constructor(totalNetAmount, totalDeductions, totalGrossAmount) {
        this.totalNetAmount = totalNetAmount;
        this.totalDeductions = totalDeductions;
        this.totalGrossAmount = totalGrossAmount;
    }
}

export default class NksPaymentTotals extends LightningElement {
    @api paymentGroups;
    @api labels;

    //Returns an array of YtelseTotal objects
    get ytelseTotals() {
        let ytelseTotals = {};
        let totalArray = [];

        if (this.paymentGroups) {
            this.paymentGroups.forEach((paymentGroup) => {
                if (paymentGroup) {
                    paymentGroup.forEach((payment) => {
                        if (payment.data.ytelseListe) {
                            payment.data.ytelseListe.forEach((ytelse) => {
                                if (ytelseTotals.hasOwnProperty(ytelse.ytelsestype.value)) {
                                    ytelseTotals[ytelse.ytelsestype.value].totalNetAmount +=
                                        ytelse.ytelseNettobeloep;
                                    ytelseTotals[ytelse.ytelsestype.value].totalDeductions +=
                                        ytelse.skattsum + ytelse.trekksum;
                                    ytelseTotals[ytelse.ytelsestype.value].totalGrossAmount +=
                                        ytelse.ytelseskomponentersum;
                                } else {
                                    ytelseTotals[ytelse.ytelsestype.value] = new Totals(
                                        ytelse.ytelseNettobeloep,
                                        ytelse.skattsum + ytelse.trekksum,
                                        ytelse.ytelseskomponentersum
                                    );
                                }
                            });
                        }
                    });
                }
            });
        }

        for (const [key, value] of object.entries(ytelseTotals)) {
            totalArray.push(new YtelseTotal(key, value));
        }

        return totalArray;
    }

    get totalNetAmount() {
        let total = 0;
        if (this.paymentGroups) {
            this.paymentGroups.forEach((paymentGroup) => {
                if (paymentGroup) {
                    paymentGroup.forEach((payment) => {
                        if (payment.data.ytelseListe) {
                            payment.data.ytelseListe.forEach((ytelse) => {
                                total += ytelse.ytelseNettobeloep;
                            });
                        }
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
