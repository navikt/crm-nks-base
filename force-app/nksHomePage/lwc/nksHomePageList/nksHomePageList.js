import { LightningElement, api, track } from 'lwc';
import getList from '@salesforce/apex/NKS_HomePageController.getList';
import getKnowledgeList from '@salesforce/apex/NKS_HomePageController.getKnowledgeList';
import getCaseList from '@salesforce/apex/NKS_HomePageController.getCaseList';
import getAnnouncementList from '@salesforce/apex/NKS_HomePageController.getAnnouncementList';
import getSkills from '@salesforce/apex/NKS_HomePageController.getUserSkills';
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

    refreshList = () => {
        const rand = Math.floor(Math.random() * (60000 - 1 + 1) + 1);
        // eslint-disable-next-line @locker/locker/distorted-window-set-timeout, @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.loadList();
        }, rand);
    };

    connectedCallback() {
        this.showSpinner = true;
        if (this.isSTO || this.objectName === 'LiveChatTranscript') {
            this._filter += " AND OwnerId='" + userId + "'";
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

        if (this.initRun === false) {
            this.initRun = true;
            if (this.filterbyskills === true) {
                getSkills()
                    .then((data) => {
                        this.userSkills = data;
                        this.loadList();
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
                    });
            } else {
                this.loadList();
            }
        }
    }
    handleError() {
        onError((error) => {
            console.log('Received error from empApi: ', JSON.stringify(error));
            this.handleSubscribe();
        });
    }

    loadList() {
        let promise;
        switch (this.objectName) {
            case 'Case':
                promise = this.getCaseList();
                break;
            case 'NKS_Announcement__c':
                promise = this.getAnnouncementList();
                break;
            case 'Knowledge__kav':
                promise = this.getKnowledgeList();
                break;
            default:
                promise = this.getList();
                break;
        }

        promise
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

        if (!this.isEmpSubscribed) {
            this.handleSubscribe();
            this.handleError();
        }
    }

    getKnowledgeList() {
        console.log('getKnowledgeList');
        return new Promise((resolve, reject) => {
            getKnowledgeList({
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
            })
                .then((data) => {
                    resolve(data);
                })
                .catch((error) => {
                    reject(error);
                });
        });
    }

    getCaseList() {
        console.log('getCaseList');
        return new Promise((resolve, reject) => {
            getCaseList({
                title: this.title,
                content: this.content,
                objectName: this.objectName,
                filter: this.filter,
                orderBy: this.orderby,
                limitNumber: this.limit,
                dateField: this.datefield
            })
                .then((data) => {
                    resolve(data);
                })
                .catch((error) => {
                    reject(error);
                });
        });
    }

    getAnnouncementList() {
        console.log('getAnnouncementList');
        return new Promise((resolve, reject) => {
            getAnnouncementList({
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
            })
                .then((data) => {
                    resolve(data);
                })
                .catch((error) => {
                    reject(error);
                });
        });
    }

    getList() {
        console.log('getList');
        return new Promise((resolve, reject) => {
            getList({
                title: this.title,
                content: this.content,
                objectName: this.objectName,
                filter: this.filter,
                orderBy: this.orderby,
                limitNumber: this.limit,
                dateField: this.datefield
            })
                .then((data) => {
                    resolve(data);
                })
                .catch((error) => {
                    reject(error);
                });
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
        if (this.refreshPageAutomatically && this.objectName === 'NKS_Announcement__c')
            subscribe(this.channelName, -1, this.refreshList).then((response) => {
                console.log(
                    `Subscription request for object ${this.objectName} sent to: ${JSON.stringify(response.channel)}`
                );
                this.subscription = response;
            });
    }

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

    get isEmpSubscribed() {
        return Object.keys(this.subscription).length !== 0 && this.subscription.constructor === Object;
    }

    get newsRecords() {
        let sortedList = [];
        let recordsToSort = [];

        if (this.isNews && this.records && Array.isArray(this.records)) {
            recordsToSort = JSON.parse(JSON.stringify(this.records));
            sortedList = recordsToSort.sort(function (x, y) {
                let index = 0;

                // pinned items first
                if (x.pin === y.pin) {
                    index = 0;
                } else {
                    if (x.pin === true) {
                        index = -1;
                    } else {
                        index = 1;
                    }
                }
                return index;
            });
        }
        return sortedList;
    }

    get isNews() {
        if (this.objectName === 'NKS_Announcement__c' && this.filter && this.filter.includes('News')) {
            return true;
        }
        return false;
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

    get lastIndex() {
        let index = 0;
        if (this.objectName === 'LiveChatTranscript' || this.isSTO) {
            index = this.records.length - 1;
        }
        return index;
    }
}
