import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class NksHomePageUsefulLinks extends NavigationMixin(LightningElement) {
    test() {
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
