import { LightningElement, api, track } from 'lwc';
import getList from '@salesforce/apex/NKS_HomePageController.getList';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, onError } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import userId from '@salesforce/user/Id';

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
    @api showimage = false;
    @api filterbyskills = false;
    @api refreshPageAutomatically = false;
    @api enableRefresh = false;

    @track listCount = 3;
    @track records = [];

    showSpinner = false;
    isInitiated = false;
    channelName = '/topic/Announcement_Updates';
    subscription = {};
    pageurl;
    initRun = false;

    connectedCallback() {
        this.isInitiated = true;

        // Add userId to filter for STO and Chat
        if (this.isSTO || this.objectName === 'LiveChatTranscript') {
            // eslint-disable-next-line @lwc/lwc/no-api-reassignments
            this.filter += " AND OwnerId='" + userId + "'";
            console.log(this.objectName + ': ' + this.filter);
        }

        // Navigate to list
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

        // Refresh list for Announcement automatically
        this.handleSubscribe();
    }

    renderedCallback() {
        if (this.initRun === false) {
            this.initRun = true;
            this.loadList();
        }
    }

    loadList() {
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
            .then((data) => {
                this.records = data;
                return this.records;
            })
            .catch((error) => {
                let message = 'Unknown error';
                if (Array.isArray(error.body)) {
                    message = error.body.map((e) => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    message = error.body.message;
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.showSpinner = false;
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

    loadMoreList() {
        this.listCount += 3;
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        this.limit = this.listCount;
        this.loadList();
    }

    refreshComponent() {
        this.showSpinner = true;
        this.loadList();
    }

    get isKnowledge() {
        return this.objectName === 'Knowledge__kav' ? true : false;
    }

    get hasRecord() {
        return this.records.length > 0 ? true : false;
    }

    get isSTO() {
        return this.objectName === 'Case' && this.filter.includes('STO_Case') ? true : false;
    }

    get isStripedList() {
        return this.objectName === 'LiveChatTranscript' || this.isSTO ? true : false;
    }

    get setEmptyStateForCase() {
        return !this.hasRecord && this.isSTO ? true : false;
    }

    get setEmptyStateForChat() {
        return !this.hasRecord && this.objectName === 'LiveChatTranscript' ? true : false;
    }

    get lastIndex() {
        let index = 0;
        if (this.objectName === 'LiveChatTranscript' || this.isSTO) {
            index = this.records.length - 1;
        }
        return index;
    }
}
