import { LightningElement, api } from 'lwc';

export default class NksCustomSvg extends LightningElement {
    @api size;
    @api altText;
    @api src;

    get iconClasses() {
        console.log(this.src);
        let styleClasses = 'slds-icon slds-icon-text-default';
        switch (this.size) {
            case 'xx-small':
                return styleClasses + ' slds-icon_xx-small';
            case 'x-small':
                return styleClasses + ' slds-icon_x-small';
            case 'small':
                return styleClasses + ' slds-icon_small';
            case 'large':
                return styleClasses + ' slds-icon_large';
            default:
                return styleClasses;
        }
    }
}
