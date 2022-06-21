import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getReadyResponse from '@salesforce/apex/NKS_HomePageController.getReadyResponses';

export default class NksHomePageUsefulLinks extends NavigationMixin(LightningElement) {
    @track records = [];

    isInitiated = false;
    size;
    className;

    connectedCallback() {
        this.isInitiated = true;
        this.loadList();
    }

    loadList() {
        getReadyResponse()
            .then((result) => {
                this.records = result;
            })
            .catch((error) => {
                console.log(error);
            });
    }

    get showReadyResponse() {
        let show;
        if (this.records == null) {
            show = false;
            this.size = 12;
            this.className = '';
        } else {
            show = true;
            this.size = 7;
            this.className = 'slds-var-p-left_large';
        }

        return show;
    }

    navigateToKnowledge() {
        this[NavigationMixin.Navigate]({
            type: 'standard__knowledgeArticlePage',
            attributes: {
                actionName: 'view',
                articleType: 'Knowledge',
                urlName: encodeURIComponent('Felles-Trussel-trakassering-og-sjikane')
            }
        });
    }
}
