import { LightningElement, api, wire } from 'lwc';
import getField from '@salesforce/apex/NKS_HomePageController.getField';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class NksHomePageText extends NavigationMixin(LightningElement) {
    @api cardTitle;
    @api iconName;
    @api type;
    @api listViewName;
    @api enableRefresh = false;

    text;
    pageUrl;
    wiredField;
    showSpinner = false;
    recordTypeName = '';

    @wire(getField, {
        type: '$recordTypeName'
    })
    wiredData(result) {
        this.wiredField = result;
        this.loadField();
    }

    connectedCallback() {
        this.recordTypeName = this.getRecordTypeNameMap();
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

    loadField() {
        const { error, data } = this.wiredField;
        if (data) {
            this.text = data && data.length > 0 ? data : null;
        } else if (error) {
            console.log('An error occurred: ' + JSON.stringify(error, null, 2));
        }
    }

    refreshField() {
        this.showSpinner = true;
        refreshApex(this.wiredField)
            .then(() => {
                this.loadField();
            })
            .finally(() => {
                this.showSpinner = false;
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

    getRecordTypeNameMap() {
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

    get isSalesforceUpdate() {
        return this.type === 'Salesforce oppdatering';
    }

    get isTraffic() {
        return this.type === 'Trafikk';
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

    /*
    isInitiated = false;
    channelName = '/topic/Announcement_Updates';
    subscription = {};

     get isEmpSubscribed() {
        return Object.keys(this.subscription).length !== 0 && this.subscription.constructor === Object;
    }

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
    */
}
