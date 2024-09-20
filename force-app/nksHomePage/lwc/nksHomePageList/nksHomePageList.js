import { LightningElement, api, track } from 'lwc';
import getList from '@salesforce/apex/NKS_HomePageController.getList';
import getKnowledgeList from '@salesforce/apex/NKS_HomePageController.getKnowledgeList';
import getCaseList from '@salesforce/apex/NKS_HomePageController.getCaseList';
import getAnnouncementList from '@salesforce/apex/NKS_HomePageController.getAnnouncementList';
import getSkills from '@salesforce/apex/NKS_HomePageController.getUserSkills';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, onError } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';

export default class nksHomePageList extends NavigationMixin(LightningElement) {
    @api cardLabel;
    @api iconName;
    @api title;
    @api content;
    @api objectName;
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
    userSkills = [];
    showSpinner = false;
    channelName = '/topic/Announcement_Updates';
    subscription = {};
    pageurl;
    initRun = false;
    _filter;

    @api
    get filter() {
        return this._filter;
    }

    set filter(value) {
        this._filter = value;
    }

    connectedCallback() {
        this.showSpinner = true;

        if (this.isSTO || this.objectName === 'LiveChatTranscript') {
            this._filter += " AND OwnerId='" + userId + "'";
        }
        this.fetchComponentData();
        this.generateListUrl();
        this.setupEmpSubscription();
    }

    fetchComponentData() {
        this.showSpinner = true;

        if (!this.initRun) {
            this.initRun = true;
            if (this.filterbyskills) {
                this.fetchUserSkillsAndListOfRecords();
            } else {
                this.fetchListOfRecords();
            }
        }
    }

    fetchUserSkillsAndListOfRecords() {
        getSkills()
            .then((data) => {
                this.userSkills = data;
                this.fetchListOfRecords();
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    fetchListOfRecords() {
        let promise;
        switch (this.objectName) {
            case 'Case':
                promise = getCaseList({
                    title: this.title,
                    content: this.content,
                    objectName: this.objectName,
                    filter: this.filter,
                    orderBy: this.orderby,
                    limitNumber: this.limit,
                    dateField: this.datefield
                });
                break;
            case 'NKS_Announcement__c':
                promise = getAnnouncementList({
                    title: this.title,
                    content: this.content,
                    objectName: this.objectName,
                    filter: this.filter,
                    orderBy: this.orderby,
                    limitNumber: this.limit,
                    dateField: this.datefield,
                    showImage: this.showimage,
                    filterBySkills: this.filterbyskills,
                    skills: this.userSkills
                });
                break;
            case 'Knowledge__kav':
                promise = getKnowledgeList({
                    title: this.title,
                    content: this.content,
                    objectName: this.objectName,
                    filter: this.filter,
                    orderBy: this.orderby,
                    limitNumber: this.limit,
                    dateField: this.datefield,
                    showImage: this.showimage,
                    filterBySkills: this.filterbyskills,
                    skills: this.userSkills
                });
                break;
            default:
                getList({
                    title: this.title,
                    content: this.content,
                    objectName: this.objectName,
                    filter: this.filter,
                    orderBy: this.orderby,
                    limitNumber: this.limit,
                    dateField: this.datefield
                });
                break;
        }

        promise
            .then((data) => {
                this.records = data;
                // Only refresh on run
                this.refreshComponent();
            })
            .catch((error) => {
                this.handleError(error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    generateListUrl() {
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

    setupEmpSubscription() {
        if (this.isEmpSubscribed) {
            return;
        }
        if (this.refreshPageAutomatically && this.objectName === 'NKS_Announcement__c') {
            subscribe(this.channelName, -1, this.refreshList)
                .then((response) => {
                    console.log(`Subscription request for object ${this.objectName} sent to: ${JSON.stringify(response.channel)}`);
                    this.subscription = response;
                    if (!this.isEmpSubscribed) {
                        this.printError();
                    }
                })
                .catch((error) => {
                    this.printError(error);
                });
        }
    }

    handleError(error) {
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
    }

    printError() {
        onError((error) => {
            console.error('Received error from empApi: ', JSON.stringify(error));
        });
    }

    refreshList() {
        this.fetchListOfRecords()
    }

    paginateListOfRecords() {
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        this.limit += 3;
        this.fetchListOfRecords();
    }

    // TODO: See if this works
    recordIds = [];
    async refreshComponent() {
        this.showSpinner = true;
        this.recordIds = this.records.map(record => {return {recordId: record.recordId}});
        await notifyRecordUpdateAvailable(this.recordIds);
        this.showSpinner = false;
    }

    get isEmpSubscribed() {
        return Object.keys(this.subscription).length !== 0 && this.subscription.constructor === Object;
    }


    get newsRecords() {
        if (this.isNews && this.records && Array.isArray(this.records)) {
            let sortedList = [...this.records];
    
            // Sort by 'pin' property in descending order (pinned items first)
            sortedList.sort((a, b) => (b.pin === a.pin ? 0 : b.pin ? 1 : -1));
            return sortedList;
        }
        return [];
    }

    get isNews() {
        return this.objectName === 'NKS_Announcement__c' && this.filter?.includes('News');
    }

    get isKnowledge() {
        return this.objectName === 'Knowledge__kav';
    }

    get hasRecord() {
        return this.records.length > 0;
    }

    get isSTO() {
        return this.objectName === 'Case' && this.filter.includes('STO_Case');
    }

    get isStripedList() {
        return this.objectName === 'LiveChatTranscript' || this.isSTO;
    }

    get setEmptyStateForCase() {
        return !this.hasRecord && this.isSTO;
    }

    get lastIndex() {
        return (this.objectName === 'LiveChatTranscript' || this.isSTO) ? this.records.length - 1 : 0;
    }
}
