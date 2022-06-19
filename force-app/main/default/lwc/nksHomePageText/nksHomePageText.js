import { LightningElement, wire, track, api } from 'lwc';
import getAnnouncement from '@salesforce/apex/NKS_HomePageController.getAnnouncement';
import getRecord from '@salesforce/apex/NKS_HomePageController.getRecord';

export default class NksHomePageText extends LightningElement {
    @api cardTitle;
    @api iconName;
    @api type;

    @track record;

    isInitiated = false;
    recordId;
    lastModifiedDate;
    text;

    connectedCallback() {
        this.isInitiated = true;
        this.loadData();
    }

    loadData() {
        getAnnouncement({
            type: this.type
        })
            .then((data) => {
                this.record = data;
                this.recordId = this.record.Id;
                this.lastModifiedDate = this.record.LastModifiedDate;
                this.text = this.record.NKS_Information__c;
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
        return this.isOperational && !this.text ? true : false;
    }

    get isOperational() {
        return this.type === 'Teknisk og drift' ? true : false;
    }

    @wire(getRecord, { recordId: '$recordId', lastModifiedDate: '$lastModifiedDate' })
    wiredRecord({ error, data }) {
        if (data) {
            this.record = data;
        } else if (error) {
            console.log('Error occurred when tried to fetch record: ' + JSON.stringify(error, null, 2));
        }
    }
}
