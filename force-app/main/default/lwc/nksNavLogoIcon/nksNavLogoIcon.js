import { LightningElement, api } from 'lwc';
import navLogoIcon from '@salesforce/resourceUrl/NKS_nav_logo_rod';

export default class NksNavLogoIcon extends LightningElement {
    @api size;
    @api altText;
    @api src;

    get navLogo() {
        return navLogoIcon + '#rodLogo';
    }
}
