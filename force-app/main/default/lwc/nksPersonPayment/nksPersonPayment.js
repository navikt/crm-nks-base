import { LightningElement, api } from 'lwc';

export default class NksPersonPayment extends LightningElement {
    @api payment;

    connectedCallback() {
        console.log(JSON.stringify(this.payment, null, 2));
    }
}
