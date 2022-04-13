import { LightningElement, api, track, wire } from 'lwc';
import getNews from '@salesforce/apex/NKS_HomePageController.getNews';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import FULL_NAME from '@salesforce/schema/User.NKS_FullName__c';

export default class NksHomePageNews extends LightningElement {
    @api recordId;
    @api enableRefresh = false;

    @track news;
    @track user;

    showSpinner = false;
    wiredNews;
    userId;
    author;
    title;
    publishDate;
    lastModifiedDate;
    information;
    imageURL;

    connectedCallback() {}

    @wire(getNews, {
        recordId: '$recordId'
    })
    wiredData(result) {
        this.wiredNews = result;
        this.loadNews();
    }

    @wire(getRecord, {
        recordId: '$userId',
        fields: [FULL_NAME]
    })
    wiredUser({ error, data }) {
        if (error) {
            console.log(error);
        } else if (data) {
            this.user = data;
            if (this.user) {
                this.author = getFieldValue(data, FULL_NAME);
            }
        }
    }

    loadNews() {
        const { error, data } = this.wiredNews;
        if (data) {
            this.news = data;
            if (this.news) {
                this.title = this.news.Name;
                this.userId = this.news.NKS_News_Author__c;
                this.publishDate = this.news.NKS_News_Publish_Date__c;
                this.lastModifiedDate = this.news.LastModifiedDate;
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
        refreshApex(this.wiredNews)
            .then(() => {
                this.loadNews();
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }
}
