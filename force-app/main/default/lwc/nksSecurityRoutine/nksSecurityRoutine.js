import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NksSecurityRoutine extends NavigationMixin(LightningElement) {
    @api articleId;

    handleSecurity() {
        const splitArticles = this.articleId.split(',');

        for (let i = 0; i < splitArticles.length; i++) {
            const article = splitArticles[i];
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this[NavigationMixin.Navigate]({
                    type: 'standard__knowledgeArticlePage',
                    attributes: {
                        actionName: 'view',
                        articleType: 'Knowledge',
                        urlName: encodeURIComponent(article)
                    }
                });
            }, 1000 * i);
        }
    }
}
