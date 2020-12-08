import { LightningElement, api, track, wire } from 'lwc';
import getPersonBadgesAndInfo from '@salesforce/apex/NKS_PersonBadgesController.getPersonBadgesAndInfo';

export default class NksPersonBadges extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api personRelationField;
    @api addBoxLayout = false;
    @api assistiveHeader;

    @track wiredBadge;
    @track badges = [];
    @track securityMeasures = [];
    @track interpreterSpokenLanguages = [];
    @track guardianships = [];
    @track powerOfAttorney;
    @track entitlements = [];

    errorMessage;
    infoPanelToShow = '';

    connectedCallback() {
        this.setAttribute('title', this.assistiveHeader);
        this.template.ariaLabel = this.assistiveHeader;
    }

    get hasBadges() {
        return this.badges && 0 < this.badges.length ? true : false;
    }

    get showIntepreterSpokenLanguage() {
        return 'spokenLanguageIntepreter' === this.infoPanelToShow;
    }

    get showSecurityMeasures() {
        return 'securityMeasures' === this.infoPanelToShow;
    }

    get showGuardianship() {
        return 'guardianshipOrFuturePowerOfAttorney' === this.infoPanelToShow;
    }

    get showPowerOfAttorney() {
        return 'powerOfAttorney' === this.infoPanelToShow;
    }

    get showEntitlements() {
        return 'entitlements' === this.infoPanelToShow;
    }

    get backgroundTheme() {
        if (true === this.addBoxLayout) {
            return 'slds-box slds-box_xx-small slds-theme_alert-texture slds-theme_info';
        }
        return '';
    }


    @wire(getPersonBadgesAndInfo, { field: '$personRelationField', parentObject: '$objectApiName', parentRecordId: '$recordId' })
    wiredBadgeInfo(value) {
        this.wiredBadge = value;

        const { data, error } = value;
        this.errorMessage = undefined;

        if (data) {
            this.badges = data.badges;
            this.securityMeasures = data.securityMeasures;
            this.interpreterSpokenLanguages = data.spokenLanguagesIntepreter;
            this.guardianships = data.guardianships;
            this.powerOfAttorney = data.powerOfAttorney;
            this.entitlements = data.entitlements;
        }

        if (error) {
            this.error = error.body.message;
        }
    }

    onKeyPressHandler(event) {
        if (event.which === 13 || event.which === 32) {
            let selectedBadge = event.target.dataset.id;
            this.handleSelectedBadge(selectedBadge);
        }
    }

    onClickHandler(event) {
        let selectedBadge = event.target.dataset.id;
        this.handleSelectedBadge(selectedBadge);
    }

    handleSelectedBadge(selectedBadge) {
        if (this.infoPanelToShow === selectedBadge) {
            this.infoPanelToShow = '';
        } else {
            this.infoPanelToShow = selectedBadge;
        }
    }

}