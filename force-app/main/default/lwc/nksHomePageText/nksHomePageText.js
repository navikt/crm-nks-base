import { LightningElement, api } from 'lwc';
import getField from '@salesforce/apex/NKS_HomePageController.getField';
import { subscribe, onError } from 'lightning/empApi';

export default class NksHomePageText extends LightningElement {
    @api cardTitle;
    @api iconName;
    @api type;

    isInitiated = false;
    text;
    channelName = '/topic/Announcement_Updates';
    subscription = {};

    connectedCallback() {
        this.isInitiated = true;
        this.loadField();
        this.handleError();
    }

    handleError() {
        onError((error) => {
            console.log('Received error from empApi: ', JSON.stringify(error));
            this.handleSubscribe();
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
