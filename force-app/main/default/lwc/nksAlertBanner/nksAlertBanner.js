import { LightningElement, api } from 'lwc';

export default class NksAlertBanner extends LightningElement {
    @api type;
    @api message;

    get iconName() {
        switch (this.type) {
            case 'Error':
                return 'utility:error';
            case 'Warning':
                return 'utility:warning';
            default:
                return 'utility:info';
        }
    }

    get bannerClass() {
        switch (this.type) {
            case 'Error':
                return 'slds-notify slds-notify_alert slds-theme_alert-texture slds-theme_error';
            case 'Warning':
                return 'slds-notify slds-notify_alert slds-theme_alert-texture slds-theme_warning';
            default:
                return 'slds-notify slds-notify_alert slds-theme_alert-texture slds-theme_info';
        }
    }
}
