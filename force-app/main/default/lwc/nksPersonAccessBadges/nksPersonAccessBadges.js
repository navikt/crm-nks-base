import { LightningElement, api, track, wire } from 'lwc';
import getPersonBadgesAndInfo from '@salesforce/apex/NKS_PersonAccessBadgesController.getPersonAccessBadges';

export default class NksPersonAccessBadges extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api personRelationField;
    @api addBoxLayout = false;
    @api assistiveHeader;
    @api addAssistiveHeader = false;
    @api cssClasses = '';
    _hideNoAccessMessage = false;

    @track wiredBadge;
    @track badges = [];

    isLoaded = false;

    errorMessage;

    @api get hideNoAccessMessage() {
        return this._hideNoAccessMessage;
    }

    set hideNoAccessMessage(value) {
        if ('true' === value || 'TRUE' === value || true === value) {
            this._hideNoAccessMessage = true;
        } else {
            this._hideNoAccessMessage = false;
        }
    }

    get showNoBadgesAssistiveMessage() {
        return this.addAssistiveHeader === true && !this.hasBadges;
    }

    get hasBadges() {
        return this.badges && 0 < this.badges.length ? true : false;
    }

    get showBadges() {
        return this.isLoaded === true ? this.hasBadges : false;
    }

    get showMessageWhenNoBadges() {
        return this.hideNoAccessMessage === false && this.isLoaded === true && this.hasBadges === false;
    }

    get containerClasses() {
        if (true === this.addBoxLayout) {
            return 'slds-box slds-box_xx-small slds-theme_alert-texture slds-theme_info';
        } else if (this.cssClasses.length > 0) {
            return this.cssClasses;
        }

        return '';
    }

    @wire(getPersonBadgesAndInfo, {
        field: '$personRelationField',
        parentObject: '$objectApiName',
        parentRecordId: '$recordId'
    })
    wiredBadgeInfo(value) {
        this.wiredBadge = value;

        const { data, error } = value;
        this.errorMessage = undefined;

        if (data) {
            this.badges = data;
            this.setAssistiveHeader();
            this.isLoaded = true;
        }

        if (error) {
            this.errorMessage = error.body.message;
        }
    }

    setAssistiveHeader() {
        if (true === this.addAssistiveHeader && this.badges.length > 0) {
            this.setAttribute('title', this.assistiveHeader);
            this.template.ariaLabel = this.assistiveHeader;
        }
    }
}
