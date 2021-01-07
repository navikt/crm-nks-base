import { LightningElement, api, track } from 'lwc';
import getList from '@salesforce/apex/NKS_HomePageController.getList';

export default class nksHomePageList extends LightningElement {
    @api cardLabel;
    @api iconName;
    @api fields;
    @api objectName;
    @api filter;

    @track records;
    error;

    connectedCallback() {
        this.loadList();
    }

    loadList() {
        getList({
            fields: this.fields,
            objectName: this.objectName,
            filter: this.filter,
        })
            .then(result => {
                this.records = result;
            })
            .catch(error => {
                this.error = error;
            });
    }

    //@wire(getList, { fields: 'Name', objectName: 'NKS_Announcement__c', filter: 'NKS_Type__c' })
    //relations;

}
