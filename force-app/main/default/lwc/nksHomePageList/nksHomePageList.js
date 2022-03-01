import { LightningElement, api, track } from 'lwc';
import getList from '@salesforce/apex/NKS_HomePageController.getList';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, onError } from 'lightning/empApi';
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
    @api datefield;
    @api showimage;
    @api filterbyskills;
    @api refreshPageAutomatically;
    isInitiated = false;
    channelName = '/topic/Announcement_Updates';
    subscription = {};

    @track records = [];
    @track listCount;
    @api cardFlag = false;
    error;
    pageurl;

    connectedCallback() {
        this.isInitiated = true;
        this.listCount = 3;
        this.cardFlag = this.objectName === 'Knowledge__kav';
        if (this.cardFlag) this.limit = this.listCount;

        this.loadList();
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectName,
                actionName: 'list'
            },
            state: {
                filterName: this.listviewname
            }
        }).then((url) => {
            this.pageUrl = url;
        });

        this.handleSubscribe();
    }

    loadList() {
        if (this.isCase) {
            getList({
                title: 'STO_Category__c',
                content: null,
                objectName: 'Case',
                filter: "IsClosed=false AND recordType.DeveloperName='STO_Case' AND OwnerId=:userId",
                orderby: 'CreatedDate DESC',
                limitNumber: 3,
                datefield: 'CreatedDate',
                showimage: false,
                filterbyskills: false
            })
                .then((result) => {
                    this.records = result;
                })
                .catch((error) => {
                    this.error = error;
                });
        }
        getList({
            title: this.title,
            content: this.content,
            objectName: this.objectName,
            filter: this.filter,
            orderby: this.orderby,
            limitNumber: this.limit,
            datefield: this.datefield,
            showimage: this.showimage,
            filterbyskills: this.filterbyskills
        })
            .then((result) => {
                this.records = result;
            })
            .catch((error) => {
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

    handleSubscribe() {
        if (this.refreshPageAutomatically)
            subscribe(this.channelName, -1, this.refreshList).then((response) => {
                console.log('Subscription request sent to: ', JSON.stringify(response.channel));
                this.subscription = response;
            });
        onError((error) => {
            console.error('Received error from server: ', JSON.stringify(error));
        });
    }

    refreshList = () => {
        this.isInitiated = true;
        this.loadList();
    };

    lastFlereList(event) {
        this.listCount += 3;
        this.limit = this.listCount;
        this.loadList();
    }

    get isCase() {
        return this.objectName === 'Case' ? true : false;
    }

    get isStripedList() {
        return this.objectName === 'LiveChatTranscript' || this.objectName === 'Case' ? true : false;
    }

    get hasRecord() {
        return this.records.length > 0 ? true : false;
    }

    get setEmptyState() {
        return !this.hasRecord && this.isStripedList ? true : false;
    }

    get lastIndex() {
        if (this.objectName === 'LiveChatTranscript' || this.objectName === 'Case') {
            return this.records.length - 1;
        }
    }
}
