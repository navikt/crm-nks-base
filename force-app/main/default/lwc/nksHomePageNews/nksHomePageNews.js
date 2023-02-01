import { LightningElement, api, track, wire } from 'lwc';
import getNews from '@salesforce/apex/NKS_HomePageController.getNews';
import countViews from '@salesforce/apex/NKS_HomePageController.countNewsViews';
import hasPermission from '@salesforce/customPermission/NKS_Manage_News';
import { refreshApex } from '@salesforce/apex';

export default class NksHomePageNews extends LightningElement {
    @api recordId;
    @api enableRefresh = false;

    @track news;

    showSpinner = false;
    wiredNews;
    wiredCounter;
    title;
    publishDate;
    lastModifiedDate;
    lastUpdatedDate;
    otherAuthors;
    information;
    imageURL;
    siteURL;
    numOfViews = 0;

    connectedCallback() {
        this.siteURL = '/apex/Audit_Log_Announcement?Id=' + this.recordId;
    }

    @wire(getNews, {
        recordId: '$recordId'
    })
    wiredData(result) {
        this.wiredNews = result;
        this.loadNews();
    }

    @wire(countViews, {
        recordId: '$recordId'
    })
    wiredCountViews(result) {
        this.wiredCounter = result;
        this.loadCounter();
    }

    loadCounter() {
        const { error, data } = this.wiredCounter;
        if (data) {
            this.numOfViews = data;
        } else if (error) {
            console.log(error);
        }
    }

    loadNews() {
        const { error, data } = this.wiredNews;
        if (data) {
            this.news = data;
            if (this.news) {
                this.title = this.news.Name;
                this.publishDate = this.news.NKS_News_Publish_Date__c;
                this.lastUpdatedDate = this.news.NKS_News_Update_Date__c;
                this.lastModifiedDate = this.news.LastModifiedDate;
                this.otherAuthors = this.news.NKS_News_Other_Authors__c;
                this.information = this.news.NKS_Information__c;
                this.imageURL = this.news.NKS_ImageURL__c;
            }
        }
        if (error) {
            console.log(error);
        }
    }

    refreshRecord() {
        this.showSpinner = true;
        refreshApex(this.wiredCounter).then(() => {
            this.loadCounter();
        });
        refreshApex(this.wiredNews)
            .then(() => {
                this.loadNews();
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    get hasPermission() {
        return hasPermission;
    }
}
