import { LightningElement, track, api } from 'lwc';

export default class QuickTextSearch extends LightningElement {

    @api comments;
    @track isModal = false;

    showModal(event) {
        this.isModal = true;
    }

    hideModal(event) {
        this.isModal = false;
    }

}