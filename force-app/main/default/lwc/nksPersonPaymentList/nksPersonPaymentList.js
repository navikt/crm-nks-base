import { LightningElement, api, wire } from 'lwc';
import loadRecentPayments from '@salesforce/apex/NKS_PaymentListController.getRecentPayments';
import loadPaymentHistory from '@salesforce/apex/NKS_PaymentListController.getPaymentHistory';
import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.Name';

//LABEL IMPORT
import labels from './labels';

export default class NksPersonPaymentList extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api labels = labels;
    @api relationshipField;
    personId; //Salesforce ID to the person record
    personIdent;
    payments = [];
    error = false;
    errorMessage = '';
    noPaymentsMessage = labels.NO_PAYMENTS;
    paymentsLoaded = false;
    historyLoaded = false;
    groupedPayments;
    selectedPeriod;
    selectedYtelser = [];

    startDateFilter;
    endDateFilter;

    get periodOptions() {
        let today = new Date();
        let lastYear = new Date();
        lastYear.setFullYear(lastYear.getFullYear() - 1);

        let options = [
            { label: labels.PERIOD_LAST_MONTH, value: 'LAST_MONTH' },
            {
                label: labels.PERIOD_THIS_YEAR + ' (' + today.getFullYear() + ')',
                value: 'THIS_YEAR'
            },
            {
                label: labels.PERIOD_PREV_YEAR + ' (' + lastYear.getFullYear() + ')',
                value: 'PREVIOUS_YEAR'
            },
            { label: labels.PERIOD_CUSTOM, value: 'CUSTOM_PERIOD' }
        ];
        return options;
    }

    connectedCallback() {
        this.selectedPeriod = 'LAST_MONTH';
        let startDate = new Date();
        startDate.setMonth(startDate.getMonth() - 1, 1);
        this.startDateFilter = startDate;
        this.endDateFilter = new Date();

        this.getRelatedRecordId(this.relationshipField, this.objectApiName);
    }

    getRelatedRecordId(relationshipField, objectApiName) {
        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: relationshipField,
            objectApiName: objectApiName
        })
            .then((record) => {
                this.personId = this.resolve(relationshipField, record);
            })
            .catch((error) => {
                console.log(error);
            });
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

    get minStartDate() {
        let minStartDate = new Date();
        minStartDate.setFullYear(minStartDate.getFullYear() - 3);
        return minStartDate.toISOString();
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
        return this.error === false && this.paymentsLoaded === false;
    }

    get hasPayments() {
        return this.payments.length != 0 || this.historyLoaded === false;
    }

    get listTitle() {
        return (
            labels.PAYMENT_HEADER +
            ' (' +
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

    @wire(getRecord, {
        recordId: '$personId',
        fields: [PERSON_IDENT_FIELD]
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            this.personIdent = getFieldValue(data, PERSON_IDENT_FIELD);
        }
        if (error) {
            this.error = true;
            this.errorMessage = labels.NO_ACCESS;
        }
    }

    @wire(loadRecentPayments, {
        ident: '$personIdent'
    })
    wiredPaymentInfo({ error, data }) {
        if (data) {
            this.initPayments(data);
            //Async load of more data after returning recent payments
            this.getPaymentHistory();
        } else if (error) {
            console.log('ERROR: ' + JSON.stringify(error, null, 2));
            this.error = true;
            this.errorMessage = labels.API_ERROR + error.body.message;
        }
    }

    async getPaymentHistory() {
        loadPaymentHistory({ ident: this.personIdent })
            .then((data) => {
                let initYtelser = this.payments.length == 0;
                this.payments = data;
                if (initYtelser) this.initytelseSelection();
                this.filterPayments();
            })
            .catch((error) => {
                console.log('ERROR: ' + JSON.stringify(error, null, 2));
            })
            .finally(() => {
                this.historyLoaded = true;
            });
    }

    initPayments(payments) {
        this.payments = payments;
        this.paymentsLoaded = true;
        this.initytelseSelection();
        this.filterPayments();
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
            case 'LAST_MONTH':
                let startDate = new Date();
                startDate.setMonth(startDate.getMonth() - 1, 1);
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
        //INIT a filter object allowing to mutate object properties
        let filtered = JSON.parse(JSON.stringify(this.payments));
        filtered = filtered.filter((payment) => {
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

    filterYtelse(payment) {
        let filteredYtelser = payment.ytelseListe.filter((ytelse) => {
            return this.selectedYtelser.includes(ytelse.ytelsestype.value);
        });
        payment.ytelseListe = filteredYtelser;
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

    /**
     * Retrieves the value from the given object's data path
     * @param {data path} path
     * @param {JS object} obj
     */
    resolve(path, obj) {
        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || self);
    }
}
