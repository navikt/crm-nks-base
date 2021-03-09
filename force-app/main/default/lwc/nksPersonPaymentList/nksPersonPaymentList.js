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
    selectedPeriod;
    selectedYtelser = [];
    periodOptions = [
        { label: 'Siste 3 måneder', value: 'LAST_3_MONTHS' },
        { label: 'I år', value: 'THIS_YEAR' }
    ];
    filtering = false;

    startDateFilter;
    endDateFilter;

    connectedCallback() {
        this.startDateFilter = new Date();
        var endDateFilter = new Date();
        this.endDateFilter = new Date(endDateFilter.setFullYear(endDateFilter.getFullYear() - 2));
    }

    renderedCallback() {
        this.filtering = false;
    }

    get isLoading() {
        return (this.error === false && this.paymentsLoaded === false) || this.filtering;
    }

    get hasPayments() {
        return this.payments.length != 0;
    }

    get listTitle() {
        return (
            'Payments (' +
            this.paymentGroups.map((group) => group.length).reduce((a, b) => a + b, 0) +
            ')'
        );
    }

    get ytelseOptions() {
        let ytelseSet = new Set();
        let options = [];
        if (this.payments) {
            this.payments.forEach((payment) => {
                if (payment.ytelseListe && Object.keys(payment.ytelseListe).length !== 0) {
                    payment.ytelseListe.forEach((ytelse) => {
                        ytelseSet.add(ytelse.ytelsestype.value);
                    });
                }
            });
        }

        ytelseSet.forEach((ytelse) => {
            options.push({ label: ytelse, value: ytelse });
        });

        return options;
    }

    get paymentGroups() {
        let paymentList = [];
        if (this.groupedPayments) {
            Object.keys(this.groupedPayments).forEach((paymentKey) => {
                paymentList.push(this.groupedPayments[paymentKey]); //Adds a grouped array to each element in the paymentList
            });
        }
        return paymentList;
    }

    @wire(loadPayments, {
        ident: '27115337357'
    })
    wiredPaymentInfo({ error, data }) {
        if (data) {
            this.payments = data;
            this.paymentsLoaded = true;
            this.groupedPayments = this.groupPayments(this.payments);
            this.initytelseSelection();
        } else if (error) {
            console.log('ERROR: ' + JSON.stringify(error, null, 2));
            this.error = true;
        }
    }

    ytelseChanged(event) {
        let ytelseArray = event.detail.value;
        this.selectedYtelser = ytelseArray;
        this.filterPayments();
    }

    filterPayments() {
        let filtered = [];
        this.filtering = true;
        filtered = this.filterByPeriod(this.payments);
        filtered = this.filterByYtelse(filtered);
        this.groupedPayments = this.groupPayments(filtered);
    }

    filterByPeriod(payments) {
        return payments;
    }

    filterByYtelse(payments) {
        return payments.filter((payment) => {
            let hasYtelse = false;
            if (payment.ytelseListe) {
                for (let index = 0; index < payment.ytelseListe.length; index++) {
                    let ytelse = payment.ytelseListe[index].ytelsestype.value;
                    hasYtelse = this.selectedYtelser.includes(ytelse);
                    if (hasYtelse === true) break;
                }
            }
            return hasYtelse;
        });
    }

    //Default init with all values selected
    initytelseSelection() {
        let defaultSelected = [];
        this.ytelseOptions.forEach((option) => {
            defaultSelected.push(option.value);
        });

        this.selectedYtelser = defaultSelected;
    }

    groupPayments(paymentList) {
        let paymentMap = {};
        paymentList.forEach((payment) => {
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
        return paymentMap;
    }
}
