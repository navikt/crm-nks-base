import { LightningElement, api } from 'lwc';

export default class NksHeader extends LightningElement {
    @api input;
    @api headertag;
    h1 = false;
    h2 = false;
    h3 = false;
    h4 = false;
    h5 = false;
    h6 = false;

    connectedCallback() {
        if (this.headertag == 'h1') this.h1 = true;
        if (this.headertag == 'h2') this.h2 = true;
        if (this.headertag == 'h3') this.h3 = true;
        if (this.headertag == 'h4') this.h4 = true;
        if (this.headertag == 'h5') this.h5 = true;
        if (this.headertag == 'h6') this.h6 = true;
    }
}
