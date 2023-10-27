import { LightningElement, api } from 'lwc';

export default class NksPersonTab extends LightningElement {
    @api recordId;
    @api objectApiName;

    // TODO: Add logic for both account and case
    // TODO: Use labels for english/norwegian

    handleTabClick(event) {
        console.log('First');
        const tabContent2 = `Tab ${event.target.label} is now active`;
        console.log(tabContent2);
    }

    get tabConditional() {
        // TODO: Add conditions for show any information, mostly access
        return true;
    }

    get flyttingConditional() {
        // TODO: Add conditions for hiding flytting, mostly access
        return true;
    }

    receiveHeading() {
        console.log('Cwazy cupcake');
    }

    updateLoadMore() {
        console.log('What');
    }
}
