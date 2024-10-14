import { LightningElement, api, wire } from 'lwc';
import getNksStatus from '@salesforce/apex/NKS_HomePageController.getNksStatus';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class NksHomePageHighlightPanelTop extends LightningElement {
    @api fagsystemTitle = 'Status fagsystemer';
    @api navTitle = 'Status NAV.no';

    wiredFagsystem;
    wiredNav;

    fagsystem;
    _fagsystemId;
    _fagsystemInfo;
    nav;
    _navId;
    _navInfo;
    showFagsystemContent = false;
    showNavContent = false;
    lastClickedBadge = '';
    subscription = {};
    channelName = '/event/NKS_Home_Page_Event__e';

    connectedCallback() {
        this.handleSubscribe();
        this.registerErrorListener();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    @api
    get fagsystemId() {
        return this._fagsystemId;
    }

    set fagsystemId(value) {
        this._fagsystemId = value;
    }

    @api
    get fagsystemInfo() {
        return this._fagsystemInfo;
    }

    set fagsystemInfo(value) {
        this._fagsystemInfo = value;
    }

    @api
    get navId() {
        return this._navId;
    }

    set navId(value) {
        this._navId = value;
    }

    @api
    get navInfo() {
        return this._navInfo;
    }

    set navInfo(value) {
        this._navInfo = value;
    }

    @wire(getNksStatus, { title: '$fagsystemTitle' })
    wiredFagsystemData(value) {
        const { data, error } = value;
        this.wiredFagsystem = value;
        if (data) {
            this.fagsystem = this.wiredFagsystem.data;
            if (this.fagsystem) {
                this._fagsystemId = this.fagsystem.Id;
                this._fagsystemInfo = this.fagsystem.NKS_Information__c;
            }
        } else if (error) {
            console.error('Det har oppstått en feil ved henting av fagsystem status: ', error);
        }
    }

    @wire(getNksStatus, { title: '$navTitle' })
    wiredNavData(value) {
        const { data, error } = value;
        this.wiredNav = value;

        if (data) {
            this.nav = this.wiredNav.data;
            if (this.nav) {
                this._navId = this.nav.Id;
                this._navInfo = this.nav.NKS_Information__c;
            }
        } else if (error) {
            console.error('Det har oppstått en feil ved henting av nav status: ', error);
        }
    }

    handleBadgeClick(event) {
        const badgeLabel = event.detail.label;

        if (badgeLabel === 'Status fagsystemer') {
            if (this.lastClickedBadge === 'fagsystem') {
                this.showFagsystemContent = !this.showFagsystemContent;
            } else {
                this.showFagsystemContent = true;
                this.showNavContent = false;
            }
            this.lastClickedBadge = 'fagsystem';
        } else if (badgeLabel === 'Status NAV.no') {
            if (this.lastClickedBadge === 'nav') {
                this.showNavContent = !this.showNavContent;
            } else {
                this.showNavContent = true;
                this.showFagsystemContent = false;
            }
            this.lastClickedBadge = 'nav';
        }
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            console.log('New message received: ', JSON.stringify(response));
            const eventData = response.data.payload;
            const recordId = eventData.RecordId__c;

            this.refreshData(recordId);
        };

        subscribe(this.channelName, -1, messageCallback).then((response) => {
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, (response) => {
            console.log('Unsubscribed successfully: ', JSON.stringify(response));
        });
    }

    registerErrorListener() {
        onError((error) => {
            console.error('Error received: ', JSON.stringify(error));
        });
    }

    refreshData(recordId) {
        if (recordId === this.fagsystemId) {
            refreshApex(this.wiredFagsystem);
        }

        if (recordId === this.navId) {
            refreshApex(this.wiredNav);
        }
    }
}
