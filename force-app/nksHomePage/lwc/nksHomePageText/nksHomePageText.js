import { LightningElement, api, wire } from 'lwc';
import getAnnouncement from '@salesforce/apex/NKS_HomePageController.getAnnouncement';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class NksHomePageText extends NavigationMixin(LightningElement) {
    @api cardTitle;
    @api iconName;
    @api type;
    @api listViewName;
    @api enableRefresh = false;

    wiredAnnouncement;
    pageUrl;
    showSpinner = false;
    recordTypeName = '';
    information;
    openingsHoursLabel;
    openingHoursInformation;

    recordTypeMap = {
        Nyhet: 'News',
        Kampanje: 'Campaign',
        'Teknisk og drift': 'Operational',
        'Salesforce oppdatering': 'Salesforce_Update',
        Trafikk: 'Traffic'
    };

    @wire(getAnnouncement, {
        type: '$recordTypeName'
    })
    wiredData(result) {
        this.wiredAnnouncement = result;
        this.loadAnnouncement();
    }

    connectedCallback() {
        this.recordTypeName = this.recordTypeMap[this.type] || this.type;
        this.generatePageUrl();
    }

    loadAnnouncement() {
        const { error, data } = this.wiredAnnouncement;
        if (data) {
            this.information = data?.NKS_Information__c;
            this.openingsHoursLabel = data?.NKS_Opening_Hours_Label__c;
            this.openingHoursInformation = data?.NKS_Opening_Hours_Information__c;
        } else if (error) {
            console.error('An error occurred: ', error);
        }
    }

    refreshAnnouncement() {
        this.showSpinner = true;
        refreshApex(this.wiredAnnouncement)
            .then(() => this.loadAnnouncement())
            .finally(() => (this.showSpinner = false));
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

    generatePageUrl() {
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

    get isSalesforceUpdate() {
        return this.type === 'Salesforce oppdatering';
    }

    get isTraffic() {
        return this.type === 'Trafikk';
    }

    get icon() {
        return this.iconName && this.iconName.trim() !== '' ? this.iconName : null;
    }

    get showOperational() {
        return this.isOperational && this.information;
    }

    get isOperational() {
        return this.type === 'Teknisk og drift';
    }

    get showSalesforceUpdate() {
        return this.isSalesforceUpdate && this.information;
    }

    get hasOpeningHours() {
        return this.openingsHoursLabel && this.openingHoursInformation;
    }
}
