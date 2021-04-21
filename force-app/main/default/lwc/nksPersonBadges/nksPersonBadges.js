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
    @track powerOfAttorneys = [];
    @track entitlements = [];
    @track errors = [];

    infoPanelToShow = '';
    hasSecurityMeasures = false;
    hasShownSecurityMeasuresAlert = false;
    errorMessage;

    connectedCallback() {
        this.setAttribute('title', this.assistiveHeader);
        this.template.ariaLabel = this.assistiveHeader;
    }

    get hasErrors() {
        return this.errors && 0 < this.errors.length ? true : false;
    }

    get hasBadges() {
        return this.badges && 0 < this.badges.length ? true : false;
    }

    get showIntepreterSpokenLanguage() {
        return 'spokenLanguageIntepreter' === this.infoPanelToShow && 0 < this.interpreterSpokenLanguages.length;
    }

    get showSecurityMeasures() {
        return 'securityMeasures' === this.infoPanelToShow && 0 < this.securityMeasures.length;
    }

    get showGuardianship() {
        return 'guardianshipOrFuturePowerOfAttorney' === this.infoPanelToShow && 0 < this.guardianships.length;
    }

    get showPowerOfAttorney() {
        return 'powerOfAttorney' === this.infoPanelToShow && 0 < this.powerOfAttorneys.length;
    }

    get showEntitlements() {
        return 'entitlements' === this.infoPanelToShow && 0 < this.entitlements.length;
    }

    get showSecurityMeasureAlertDialog() {
        if (this.hasSecurityMeasures === true && this.hasShownSecurityMeasuresAlert === false) {
            this.hasShownSecurityMeasuresAlert = true;
            return true;
        }

        return false;
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
            this.securityMeasures = data.securityMeasures;
            this.interpreterSpokenLanguages = data.spokenLanguagesIntepreter;
            this.guardianships = data.guardianships;
            this.powerOfAttorneys = data.powerOfAttorneys;
            this.entitlements = data.entitlements;
            this.errors = data.errors;

            this.setHasSecurityMeasures();
        }

        if (error) {
            this.errorMessage = error.body.message;
        }
    }

    setHasSecurityMeasures() {
        if (this.hasSecurityMeasures === false && this.securityMeasures.length > 0) {
            this.hasSecurityMeasures = true;
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
        this.setToggle(selectedBadge);
    }

    setToggle(selectedBadge) {
        let badges = this.template.querySelectorAll('.slds-badge');
        badges.forEach((badge) => {
            if (badge.dataset.id === selectedBadge && badge.ariaPressed === 'false') {
                badge.setAttribute('aria-pressed', true);
            } else if (badge.role === 'button') {
                badge.setAttribute('aria-pressed', false);
            }
        });
    }
}
