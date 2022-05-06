import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NksSecurityRoutine extends NavigationMixin(LightningElement) {

    handleSecurity(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: 'ka02o000000MWhPAAW',
                actionName: 'view',
            },
        }).then((url) => {
            this.recordPageUrl = url;
        });
    }
}