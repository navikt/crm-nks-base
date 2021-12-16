import { LightningElement, api } from 'lwc';

export default class NksPersonPayment extends LightningElement {
    @api payment;
    @api labels;
    @api personIdent;
    expanded = false;

    get statusIcon() {
        if (this.payment.utbetalingsstatus == 'Utbetalt') {
            return 'utility:success';
        } else {
            return 'utility:spinner';
        }
    }

    get detailText() {
        return this.expanded === true ? this.labels.HIDE_DETAILS : this.labels.SHOW_DETAILS;
    }

    get paid() {
        return this.payment.utbetalingsstatus == 'Utbetalt';
    }

    get chevronIcon() {
        return this.expanded === true ? 'utility:chevronup' : 'utility:chevrondown';
    }

    get multipleYtelser() {
        return this.ytelser && this.ytelser.length > 1;
    }

    get ytelser() {
        return this.payment.ytelseListe;
    }

    get ytelserHeader() {
        if (this.multipleYtelser === true) {
            return 'Diverse ytelser';
        } else {
            return this.payment.ytelseListe[0].ytelsestype.value;
        }
    }

    toggleExpand() {
        this.expanded = !this.expanded;
    }
}
