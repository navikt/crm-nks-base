import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NksSecurityRoutine extends NavigationMixin(LightningElement) {
    @api articleId;

    handleSecurity() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.articleId,
                actionName: 'view'
            }
        }).then((url) => {
            this.recordPageUrl = url;
        });
    }
}
