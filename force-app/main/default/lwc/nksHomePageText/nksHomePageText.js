import { LightningElement, api } from 'lwc';
import getField from '@salesforce/apex/NKS_HomePageController.getField';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, onError } from 'lightning/empApi';

export default class NksHomePageText extends NavigationMixin(LightningElement) {
    @api cardTitle;
    @api iconName;
    @api type;
    @api listViewName;

    isInitiated = false;
    text;
    pageUrl;
    channelName = '/topic/Announcement_Updates';
    subscription = {};

    refreshField = (response) => {
        if (response.data.sobject.NKS_TypeFormula__c === this.type) {
            const rand = Math.floor(Math.random() * (60000 - 1 + 1) + 1);
            //eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this.isInitiated = true;
                this.loadField();
            }, rand);
        }
    };

    connectedCallback() {
        this.isInitiated = true;
        this.loadField();
        this.handleError();

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'NKS_Announcement__c',
                actionName: 'list'
            },
            state: {
                filterName: this.listViewName
            }
        }).then((url) => {
            this.pageUrl = url;
        });
    }

    get recordTypeNameMap() {
        switch (this.type) {
            case 'Nyhet':
                return 'News';
            case 'Kampanje':
                return 'Campaign';
            case 'Teknisk og drift':
                return 'Operational';
            case 'Salesforce oppdatering':
                return 'Salesforce_Update';
            case 'Trafikk':
                return 'Traffic';
            default:
                return this.type;
        }
    }

    loadField() {
        getField({
            type: this.recordTypeNameMap
        })
            .then((data) => {
                this.text = data && data.length > 0 ? data : null;
            })
            .catch((error) => {
                console.log('An error occurred: ' + JSON.stringify(error, null, 2));
            });

        if (!this.isEmpSubscribed) {
            this.handleSubscribe();
        }
    }

    handleError() {
        onError((error) => {
            console.log('Received error from empApi: ', JSON.stringify(error));
            this.handleSubscribe();
        });
    }

    handleSubscribe() {
        subscribe(this.channelName, -1, this.refreshField).then((response) => {
            this.subscription = response;
            console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
        });
    }

    navigateToList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'NKS_Announcement__c',
                actionName: 'list'
            },
            state: {
                filterName: this.listViewName
            }
        });
    }

    get hasSalesforceUpdate() {
        return this.type === 'Salesforce oppdatering' && this.text ? true : false;
    }

    get hasTraffic() {
        return this.type === 'Trafikk' && this.text ? true : false;
    }

    get isEmpSubscribed() {
        return Object.keys(this.subscription).length !== 0 && this.subscription.constructor === Object;
    }

    get icon() {
        let nameString = null;
        if (this.iconName && this.iconName !== '') nameString = this.iconName;

        return nameString;
    }

    get isEmpty() {
        return this.isOperational && !this.text ? true : false;
    }

    get isOperational() {
        return this.type === 'Teknisk og drift' ? true : false;
    }
}
