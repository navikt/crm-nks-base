import { LightningElement, api, track, wire } from 'lwc';
import getPersonBadgesAndInfo from '@salesforce/apex/NKS_PersonAccessBadgesController.getPersonAccessBadges';
import hasPersonAccess from '@salesforce/apex/NKS_PersonAccessBadgesController.hasPersonAccess';

export default class NksPersonAccessBadges extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api personRelationField;
    @api addBoxLayout = false;
    @api assistiveHeader;
    @api addAssistiveHeader = false;

    @track wiredBadge;
    @track badges = [];

    noAccessMessage = '';

    hasAccess = false;
    isLoaded = false;

    errorMessage;

    get hasBadges() {
        return this.badges && 0 < this.badges.length ? true : false;
    }

    get showBadges() {
        return this.isLoaded == true ? this.hasBadges : false;
    }

    get showNoAccess() {
        return this.isLoaded == true ? !this.hasAccess : false;
    }

    get backgroundTheme() {
        if (true === this.addBoxLayout) {
            return 'slds-box slds-box_xx-small slds-theme_alert-texture slds-theme_info';
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
            this.badges = data.badges;
            this.hasAccess = data.hasPersonAccess;
            this.noAccessMessage = data.message;
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
