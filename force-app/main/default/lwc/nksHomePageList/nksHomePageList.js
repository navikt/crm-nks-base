import { LightningElement, api, wire, track } from 'lwc';
import getList from '@salesforce/apex/NKS_HomePageController.getList';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, onError } from 'lightning/empApi';
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

    @track records = [];
    @track listCount = 3;
    @track wiredList;

    showSpinner = false;
    isInitiated = false;
    channelName = '/topic/Announcement_Updates';
    subscription = {};
    pageurl;

    connectedCallback() {
        this.isInitiated = true;
        if (this.objectName === 'Case' || this.objectName === 'LiveChatTranscript') {
            // eslint-disable-next-line @lwc/lwc/no-api-reassignments
            this.filter += " AND OwnerId='" + userId + "'";
            console.log(this.filter);
        }

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

    @wire(getList, {
        title: '$title',
        content: '$content',
        objectName: '$objectName',
        filter: '$filter',
        orderby: '$orderby',
        limitNumber: '$limit',
        datefield: '$datefield',
        showimage: '$showimage',
        filterbyskills: '$filterbyskills'
    })
    wireData(result) {
        this.wiredList = result;
        this.loadList();
    }

    loadList() {
        this.showSpinner = true;
        const { error, data } = this.wiredList;
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map((e) => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading person record',
                    message,
                    variant: 'error'
                })
            );
        } else if (data) {
            this.records = data;
            console.log(this.records.length);
        }
        this.showSpinner = false;
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
        refreshApex(this.wiredList).then(() => {
            this.loadList();
        });
    };

    loadMoreList() {
        this.listCount += 3;
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        this.limit = this.listCount;
        this.refreshList();
    }

    get isKnowledge() {
        return this.objectName === 'Knowledge__kav' ? true : false;
    }

    get isStripedList() {
        return this.objectName === 'LiveChatTranscript' || this.objectName === 'Case' ? true : false;
    }

    get hasRecord() {
        return this.records.length > 0 ? true : false;
    }

    get setEmptyStateForCase() {
        return !this.hasRecord && this.objectName === 'Case' ? true : false;
    }

    get setEmptyStateForChat() {
        return !this.hasRecord && this.objectName === 'LiveChatTranscript' ? true : false;
    }

    get lastIndex() {
        let index = 0;
        if (this.objectName === 'LiveChatTranscript') {
            index = this.records.length - 1;
        }
        if (this.objectName === 'Case') {
            index = this.records.length - 1;
        }
        return index;
    }
}
