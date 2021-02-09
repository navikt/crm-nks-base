import { LightningElement, api } from 'lwc';

export default class NksNavCaseItem extends LightningElement {
    @api navCase;
    @api selected = false; //Attribute set by parent

    caseSelected(event) {
        let selectedCase = this.navCase;
        //Sending event to parent that case was selected
        const caseSelectedEvent = new CustomEvent('caseselected', {
            detail: { selectedCase }
        });
        this.dispatchEvent(caseSelectedEvent);
    }

    get isClosed() {
        return this.navCase ? (this.navCase.lukket ? true : false) : false;
    }
}
