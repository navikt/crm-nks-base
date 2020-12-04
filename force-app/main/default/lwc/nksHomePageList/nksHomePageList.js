import { LightningElement } from 'lwc';
import getList from '@salesforce/apex/NKS_HomePageController.getList';

export default class nksHomePageList extends LightningElement {
    listitems;
    error;

    connectedCallback() {
        this.loadList();
    }

    loadList() {
        getList()
            .then(result => {
                this.listitems = result;
            })
            .catch(error => {
                this.error = error;
            });
    }
}
