import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NksHomePageListEntry extends NavigationMixin(LightningElement) {
    @api record;
    @api isKnowledge = false;
    @api isNews = false;
    @api isPinned = false;

    @track iconName = 'utility:pin';
    @track iconClass = 'slds-float_right';

    recordPageUrl;

    navigateToSObject(event) {
        event.preventDefault();
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.recordId,
                actionName: 'view'
            }
        });
    }

    connectedCallback() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.recordId,
                actionName: 'view'
            }
        }).then((url) => {
            this.recordPageUrl = url;
        });
    }

    toggle() {
        if (this.isPinned === false) {
            this.iconClass = 'slds-float_right pinned';
            this.iconName = 'utility:pinned';
            // eslint-disable-next-line @lwc/lwc/no-api-reassignments
            this.isPinned = true;
            localStorage.setItem('id', this.index);
        } else {
            this.iconClass = 'slds-float_right';
            this.iconName = 'utility:pin';
            // eslint-disable-next-line @lwc/lwc/no-api-reassignments
            this.isPinned = false;
        }
    }
}
