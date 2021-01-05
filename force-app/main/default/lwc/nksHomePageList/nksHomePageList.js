import { LightningElement, wire } from 'lwc';
import getList from '@salesforce/apex/NKS_HomePageController.getList';

export default class nksHomePageList extends LightningElement {
    @wire(getList, { recordId: '$recordId', objectApiName: '$objectApiName' })
    relations;

    /*listitems;
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
    }*/
}
