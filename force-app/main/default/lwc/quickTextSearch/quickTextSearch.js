import { LightningElement, track } from 'lwc';

export default class QuickTextSearch extends LightningElement {

    @track isModal = false;

    showModal(event) {
        this.isModal = true;
    }

    hideModal(event) {
        this.isModal = false;
    }

}