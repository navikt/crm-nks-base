import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NksSecurityRoutine extends NavigationMixin(LightningElement) {

    handleSecurity(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: 'ka03N00000083BjQAI',
                actionName: 'view',
            },
        }).then((url) => {
            this.recordPageUrl = url;
        });
    }
}