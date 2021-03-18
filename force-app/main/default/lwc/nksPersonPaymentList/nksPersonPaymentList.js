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
        { label: 'I år', value: 'THIS_YEAR' },
        { label: 'I fjor', value: 'PREVIOUS_YEAR' },
        { label: 'Egendefinert', value: 'CUSTOM_PERIOD' }
    ];

    startDateFilter;
    endDateFilter;

    connectedCallback() {
        this.selectedPeriod = 'LAST_3_MONTHS';
        let startDate = new Date();
        startDate.setMonth(startDate.getMonth() - 3, 1);
        this.startDateFilter = startDate;
        this.endDateFilter = new Date();
    }

    get minEndDate() {
        return this.startDateFilter.toISOString();
    }

    get maxEndDate() {
        return new Date().toISOString();
    }

    get maxStartDate() {
        return new Date().toISOString();
    }

    get isoStartDate() {
        return this.startDateFilter.toISOString();
    }

    get isoEndDate() {
        return this.endDateFilter.toISOString();
    }

    get customPeriod() {
        return this.selectedPeriod === 'CUSTOM_PERIOD';
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
            this.filterPayments();
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

    customDateChanged(event) {
        let validInput = true;
        const dateInputs = this.template.querySelectorAll('lightning-input');
        dateInputs.forEach((dateInput) => {
            if (dateInput.name === 'startDate' && dateInput.checkValidity() == true) {
                this.startDateFilter = new Date(dateInput.value);
            } else if (dateInput.name === 'endDate' && dateInput.checkValidity() == true) {
                this.endDateFilter = new Date(dateInput.value);
            } else {
                validInput = false;
            }
        });
        if (validInput) {
            this.filterPayments();
        }
    }

    periodChanged(event) {
        let periodFilter = event.detail.value;
        this.selectedPeriod = periodFilter;
        switch (periodFilter) {
            case 'LAST_3_MONTHS':
                let startDate = new Date();
                startDate.setMonth(startDate.getMonth() - 3, 1);
                this.startDateFilter = startDate;
                this.endDateFilter = new Date();
                break;
            case 'THIS_YEAR':
                this.startDateFilter = new Date(new Date().getFullYear(), 0, 1);
                this.endDateFilter = new Date();
                break;
            case 'PREVIOUS_YEAR':
                this.startDateFilter = new Date(new Date().getFullYear() - 1, 0, 1);
                this.endDateFilter = new Date(new Date().getFullYear() - 1, 11, 31);
                break;
            default:
                return;
        }

        this.filterPayments();
    }

    filterPayments() {
        let filtered = [];
        filtered = this.payments.filter((payment) => {
            return this.hasYtelse(payment) && this.inFilterPeriod(payment);
        });
        this.groupedPayments = this.groupPayments(filtered);
    }

    //Returns true if the payment is in the defined filter period
    inFilterPeriod(payment) {
        let paymentDate = Date.parse(payment.utbetalingsdato);
        return paymentDate >= this.startDateFilter && paymentDate <= this.endDateFilter;
    }

    //Returns true if a payment includes one of the selected ytelser
    hasYtelse(payment) {
        let hasYtelse = false;
        if (payment.ytelseListe) {
            for (let index = 0; index < payment.ytelseListe.length; index++) {
                let ytelse = payment.ytelseListe[index].ytelsestype.value;
                hasYtelse = this.selectedYtelser.includes(ytelse);
                if (hasYtelse === true) break;
            }
        }
        return hasYtelse;
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
