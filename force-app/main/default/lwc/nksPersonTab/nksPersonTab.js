import { LightningElement, api } from 'lwc';

export default class NksPersonTab extends LightningElement {
    @api recordId;
    @api objectApiName;
    personId = 'a0F1w000004cB1EEAU';
    relatedListDisabled = false;
    relatedListHeading = '';

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

    receiveHeading(event) {
        this.relatedListHeading = event.detail;
    }

    updateLoadMore(event) {
        this.relatedListDisabled = !event.detail.enabled;
    }

    get loadMoreDisabled() {
        return this.relatedListDisabled;
    }

    loadMore() {
        console.log('Bink');
        this.template.querySelector('c-nks-filtered-related-list').loadMore();
    }

    beginRefresh() {
        this.template.querySelector('c-nks-filtered-related-list').refreshList();
    }
}
