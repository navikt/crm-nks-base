import { LightningElement } from 'lwc';

export default class NksKnowledgeHelpText extends LightningElement {
    sectionClass = 'slds-accordion__section';
    sectionIconName = 'utility:chevronright';
    isExpanded = true;
    ariaHidden = false;

    handleOpen() {
        if (this.sectionClass === 'slds-accordion__section slds-is-open') {
            this.sectionClass = 'slds-accordion__section';
            this.sectionIconName = 'utility:chevronright';
            this.isExpanded = false;
            this.ariaHidden = true;
        } else {
            this.sectionClass = 'slds-accordion__section slds-is-open';
            this.sectionIconName = 'utility:chevrondown';
            this.isExpanded = true;
            this.ariaHidden = false;
        }
    }
}
