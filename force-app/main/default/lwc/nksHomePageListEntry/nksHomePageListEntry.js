import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NksHomePageListEntry extends NavigationMixin(LightningElement) {
    @api record;
    @api cardLabel;
    @api objectName;
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

    /*kunnskap*/
    get cardKunnskap() {
        if (this.objectName === 'Knowledge__kav') this.cardLabel = true;
        else this.cardLabel = false;
        return this.cardLabel;
    }
}