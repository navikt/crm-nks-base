import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NksSecurityRoutine extends NavigationMixin(LightningElement) {
    handleSecurity(){
        const config = {
            type: 'standard__webPage',
            attributes: {
                url: 'https://navdialog.lightning.force.com/lightning/r/Knowledge__kav/ka02o000000MWhPAAW/view'
            }
        };
        this[NavigationMixin.Navigate](config);
    }
}