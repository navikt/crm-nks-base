import { LightningElement, api, wire } from 'lwc';
import loadPayments from '@salesforce/apex/NKS_PaymentService.getPayments';

export default class NksPersonPaymentList extends LightningElement {
    @api recordId;
    payments = [];
    error = false;
    errorMessage = 'An error occurred'; //MAKE CUSTOM LABEL
    noPaymentsMessage = 'Brukeren har ingen utbetalinger'; //MAKE CUSTOM LABEL
    paymentsLoaded = false;
    groupedPayments;

    get isLoading() {
        return this.error === false && this.paymentsLoaded === false;
    }

    get hasPayments() {
        return this.payments.length != 0;
    }

    get listTitle() {
        return 'Payments (' + this.payments.length + ')';
    }

    get paymentGroups() {
        let paymentList = [];
        Object.keys(this.groupedPayments).forEach((paymentKey) => {
            paymentList.push(this.groupedPayments[paymentKey]); //Adds a grouped array to each element in the paymentList
        });
        console.log(JSON.stringify(paymentList, null, 2));
        return paymentList;
    }

    @wire(loadPayments, { ident: 'value' })
    wiredPaymentInfo({ error, data }) {
        if (data) {
            this.payments = data;
            this.payments.sort((a, b) => {
                return a.utbetalingsdato - b.utbetalingsdato;
            });
            this.paymentsLoaded = true;
            this.groupPayments();
            console.log(JSON.stringify(this.payments, null, 2));
        } else if (error) {
            console.log('ERROR: ' + JSON.stringify(error, null, 2));
            this.error = true;
        }
    }

    groupPayments() {
        let paymentMap = {};
        this.payments.forEach((payment) => {
            let pmtDate = new Date(payment.utbetalingsdato);
            var pmtKey = pmtDate.getFullYear() + '-' + pmtDate.getMonth();

            if (paymentMap[pmtKey] !== undefined) {
                paymentMap[pmtKey].push({ group: pmtKey, data: payment });
            } else {
                let paymentArray = [];
                paymentArray.push({ group: pmtKey, data: payment });
                paymentMap[pmtKey] = paymentArray;
            }
        });

        this.groupedPayments = paymentMap;
    }
}
