import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getUsersCurrentApp from '@salesforce/apex/NKS_HomePageController.getUsersCurrentApp';
import updateUsersCurrentApp from '@salesforce/apex/NKS_HomePageController.updateUsersCurrentApp';

export default class NksNavigateToNewApplication extends NavigationMixin(LightningElement) {
    currentApp = 'NAV_Kontaktsenter';
    connectedCallback() {
        getUsersCurrentApp().then(res => {
            this.currentApp = res;            
        });
    }

    get nextApp() {
        return this.currentApp === 'NAV_Kontaktsenter' ? 'c__NAV_Kontaktsenter_v_2' : 'c__NAV_Kontaktsenter';
    }

    get buttonTitle() {
        return this.currentApp === 'NAV_Kontaktsenter' ? 'Prøv nytt design' : 'Gå tilbake til originalt design';
    }

    get textDescription() {
        return this.currentApp === 'NAV_Kontaktsenter' ? 'Trykk på knappen for å teste nytt design i Salesforce.' : 'Trykk på knappen for å gå tilbake til originalt design i Salesforce.'
    }

    // Alternative navigation is through window.open
    /* 
        let baseUrl = window.location.origin + '/lightning/';
        let url = baseUrl + 'app/c__' + 'NAV_Kontaktsenter_v_2' + '/r/' + this.objectApiName + '/' + this.recordId + '/view';
        window.open(url, '_self');
    */
    switchApplication() {
        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__app',
                attributes: {
                    appTarget: this.nextApp
                }
            });
            updateUsersCurrentApp({ appTarget: this.nextApp.replace('c__', '').replace('standard__', '') });
        } catch (err) {
            console.error(err);
        }
    }
}