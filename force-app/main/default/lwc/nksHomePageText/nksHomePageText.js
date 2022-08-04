import { LightningElement, api } from 'lwc';
import getField from '@salesforce/apex/NKS_HomePageController.getField';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, onError } from 'lightning/empApi';

export default class NksHomePageText extends NavigationMixin(LightningElement) {
    @api cardTitle;
    @api iconName;
    _type;

    @api set type(value) {
        if (value && this.recordTypeNameMap.has(value)) {
            this._type = this.recordTypeNameMap.get(value);
        }
        this._type = '';
    }

    get type() {
        return this._type;
    }

    recordTypeNameMap = new Map[
        (['Nyhet', 'News'],
        ['Kampanje', 'Campaign'],
        ['Teknisk og drift', 'Operational'],
        ['Salesforce oppdatering', 'Salesforce Update'],
        ['Trafikk', 'Traffic'])
    ]();

    isInitiated = false;
    text;
    pageUrl;
    channelName = '/topic/Announcement_Updates';
    subscription = {};

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
                filterName: 'Salesforce_oppdateringer'
            }
        }).then((url) => {
            this.pageUrl = url;
        });
    }

    loadField() {
        getField({
            type: this.type
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

    refreshField = () => {
        this.isInitiated = true;
        this.loadField();
    };

    navigateToList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'NKS_Announcement__c',
                actionName: 'list'
            },
            state: {
                filterName: 'Salesforce_oppdateringer'
            }
        });
    }

    get hasSalesforceUpdate() {
        return this.type === 'Salesforce oppdatering' && this.text ? true : false;
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
