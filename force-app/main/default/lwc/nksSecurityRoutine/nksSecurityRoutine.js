import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NksSecurityRoutine extends NavigationMixin(LightningElement) {
    @api articleId;

    handleSecurity() {
        this[NavigationMixin.Navigate]({
            type: 'standard__knowledgeArticlePage',
            attributes: {
                actionName: 'view',
                articleType: 'Knowledge',
                urlName: encodeURIComponent(this.articleId)
            }
        });
    }
}
