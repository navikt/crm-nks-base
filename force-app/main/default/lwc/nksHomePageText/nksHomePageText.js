import { LightningElement, api } from 'lwc';
import getField from '@salesforce/apex/NKS_HomePageController.getField';
import { subscribe, onError } from 'lightning/empApi';

export default class NksHomePageText extends LightningElement {
    @api cardTitle;
    @api iconName;
    @api type;

    text = '';
    channelName = '/topic/Announcement_Updates';
    subscription = {};
    isInitiated = false;

    connectedCallback() {
        this.isInitiated = true;
        this.loadField();
        this.handleSubscribe();
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
    }

    get icon() {
        let nameString = null;
        if (this.iconName && this.iconName !== '') nameString = this.iconName;

        return nameString;
    }

    get isEmpty() {
        return this.text === null || this.text === '' ? true : false;
    }

    get isOperational() {
        return this.type === 'Teknisk og drift' ? true : false;
    }

    handleSubscribe() {
        subscribe(this.channelName, -1, this.refreshField).then((response) => {
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
        });
        onError((error) => {
            console.error('Received error from server: ', JSON.stringify(error));
        });
    }

    refreshField = () => {
        this.isInitiated = true;
        this.loadField();
    };
}
