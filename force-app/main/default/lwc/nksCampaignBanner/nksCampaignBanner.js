import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCampaign from '@salesforce/apex/NKS_HomePageController.getCampaign';

export default class NksCampaignBanner extends NavigationMixin(LightningElement) {
    @track record;

    isInitiated = false;
    isValid = false;

    connectedCallback() {
        this.isInitiated = true;
        this.showCampaign();
    }

    get altText() {
        let alt = '';
        if (this.record !== null) {
            if (this.record.Image_Alt__c == null || this.record.Image_Alt__c === '') {
                alt = this.record.Name;
            } else {
                alt = this.record.Image_Alt__c;
            }
        }
        return alt;
    }

    navigateToRecord(event) {
        event.preventDefault();
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.Id,
                actionName: 'view'
            }
        });
    }

    showCampaign() {
        getCampaign()
            .then((result) => {
                this.record = result;
                if (this.record) {
                    const fromDate = this.record.From_Date__c;
                    const toDate = this.record.To_Date__c;
                    this.isValid = new Date(toDate) - new Date(fromDate) > 0 ? true : false;
                }
            })
            .catch((error) => {
                console.log(error);
            });
    }
}
