import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class CrmChatAccountInfo extends NavigationMixin(LightningElement) {
    @api accountId; // Id of the record to display information for
    @api displayedFields = null;
    @api cardLabel;

    get recordIdSet() {
        return this.accountId != null;
    }

    get fieldList() {
        let fieldList = this.displayedFields != null ? this.displayedFields.replace(/\s/g, "").split(",") : [];
        return fieldList;
    }

    //Opens the account page on click
    navigateToAccount() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.accountId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }
}