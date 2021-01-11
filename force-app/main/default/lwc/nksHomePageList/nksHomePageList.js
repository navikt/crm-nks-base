import { LightningElement, api, track } from 'lwc';
import getList from '@salesforce/apex/NKS_HomePageController.getList';
import { NavigationMixin } from "lightning/navigation";

export default class nksHomePageList extends NavigationMixin(LightningElement) {
    @api cardLabel;
    @api iconName;
    @api title;
    @api content;
    @api objectName;
    @api filter;
    @api orderby;
    @api limit;
    @api listviewname;
    @api linklabel;
    @api showimage;

    @track records;
    error;
    pageurl;

    connectedCallback() {
        this.loadList();
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectName,
                actionName: 'list',
            },
            state: {
                filterName: this.listviewname
            }
        }).then(url => {
            this.pageUrl = url;
        });
    }

    loadList() {
        getList({
            title: this.title,
            content: this.content,
            objectName: this.objectName,
            filter: this.filter,
            orderby: this.orderby,
            limitNumber: this.limit
        })
            .then(result => {
                this.records = result;
            })
            .catch(error => {
                this.error = error;
            });
    }

    navigateToList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectName,
                actionName: 'list'
            },
            state: {
                filterName: this.listviewname
            }
        });
    }

}
