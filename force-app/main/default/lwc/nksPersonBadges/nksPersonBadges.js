import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getPersonBadgesAndInfo from '@salesforce/apex/NKS_PersonBadgesController.getPersonBadgesAndInfo';
import getPersonAccessBadges from '@salesforce/apex/NKS_PersonAccessBadgesController.getPersonAccessBadges';

export default class NksPersonBadges extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api personRelationField;
    @api addBoxLayout = false;
    @api assistiveHeader;

    @track wiredBadge;
    @track wiredPersonAccessBadge;
    @track badges = [];
    @track personAccessBadges = [];
    @track securityMeasures = [];
    @track interpreterSpokenLanguages = [];
    @track guardianships = [];
    @track powerOfAttorneys = [];
    @track entitlements = [];
    @track errorMessages = [];

    infoPanelToShow = '';

    isNavEmployee = false;
    isConfidential = false;
    uuAlertText = '';
    wireFields;

    get isLoaded() {
        return this.wiredBadge &&
            (this.wiredBadge.data || this.wiredBadge.error) &&
            this.wiredPersonAccessBadge &&
            (this.wiredPersonAccessBadge.data || this.wiredPersonAccessBadge.error)
            ? true
            : false;
    }

    get hasErrors() {
        return this.errorMessages && 0 < this.errorMessages.length ? true : false;
    }

    get hasBadges() {
        return (this.badges && 0 < this.badges.length) ||
            (this.personAccessBadges && 0 < this.personAccessBadges.length)
            ? true
            : false;
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

    get backgroundTheme() {
        if (true === this.addBoxLayout) {
            return 'slds-box slds-box_x-small slds-theme_default';
        }
        return 'slds-p-around_x-small';
    }

    connectedCallback() {
        this.wireFields = [this.objectApiName + '.Id'];
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
            if (this.isLoaded) {
                refreshApex(this.wiredBadge).then(() => {
                    this.setWiredBadge();
                });
                refreshApex(this.wiredPersonAccessBadge).then(() => {
                    this.setWiredPersonAccessBadge();
                });
            }
        }

        if (error) {
            this.addError(error);
        }
    }

    @wire(getPersonBadgesAndInfo, {
        field: '$personRelationField',
        parentObject: '$objectApiName',
        parentRecordId: '$recordId'
    })
    wiredBadgeInfo(value) {
        this.wiredBadge = value;
        this.setWiredBadge();
    }

    setWiredBadge() {
        const { data, error } = this.wiredBadge;

        if (data) {
            this.badges = data.badges;
            this.securityMeasures = data.securityMeasures;
            this.interpreterSpokenLanguages = data.spokenLanguagesIntepreter;
            this.guardianships = data.guardianships;
            this.powerOfAttorneys = data.powerOfAttorneys;
            this.entitlements = data.entitlements;
            this.errorMessages = data.errors;

            if (this.isLoaded) {
                this.setUuAlertText();
            }
        }

        if (error) {
            this.addError(error);

            if (this.isLoaded) {
                this.setUuAlertText();
            }
        }
    }

    @wire(getPersonAccessBadges, {
        field: '$personRelationField',
        parentObject: '$objectApiName',
        parentRecordId: '$recordId'
    })
    wiredPersonBadgeInfo(value) {
        this.wiredPersonAccessBadge = value;
        this.setWiredPersonAccessBadge();
    }
    setWiredPersonAccessBadge() {
        const { data, error } = this.wiredPersonAccessBadge;

        if (data) {
            this.isNavEmployee = data.some((element) => element.name === 'isNavEmployee');
            this.isConfidential = data.some((element) => element.name === 'isConfidential');
            this.personAccessBadges = data;

            if (this.isLoaded) {
                this.setUuAlertText();
            }
        }

        if (error) {
            this.addError(error);

            if (this.isLoaded) {
                this.setUuAlertText();
            }
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
        this.setExpanded(selectedBadge);
    }

    setExpanded(selectedBadge) {
        let badges = this.template.querySelectorAll('.slds-badge');
        badges.forEach((badge) => {
            if (badge.dataset.id === selectedBadge && badge.ariaExpanded === 'false') {
                badge.setAttribute('aria-expanded', true);
            } else if (badge.role === 'button') {
                badge.setAttribute('aria-expanded', false);
            }
        });
    }

    addError(error) {
        this.isLoaded = true;
        if (Array.isArray(error.body)) {
            this.errorMessages = this.errorMessages.concat(error.body.map((e) => e.message));
        } else if (error.body && typeof error.body.message === 'string') {
            this.errorMessages.push(error.body.message);
        } else {
            this.errorMessages.push(error.body);
        }
    }

    setUuAlertText() {
        let alertText = '';

        let hasSecurityMeasures = this.securityMeasures.length > 0;
        let navEmployeeText = ' er egen ansatt';
        let isConfidentialText = ' skjermet';
        let securityMeasureText = ' har ' + this.securityMeasures.length + ' sikkerhetstiltak';

        alertText += 'Bruker';
        alertText += this.isNavEmployee ? navEmployeeText : '';
        alertText +=
            this.isNavEmployee && this.isConfidential && hasSecurityMeasures
                ? ', '
                : this.isNavEmployee && this.isConfidential
                ? ' og'
                : this.isConfidential
                ? ' er'
                : '';
        alertText += this.isConfidential ? isConfidentialText : '';
        alertText += (this.isNavEmployee || this.isConfidential) && hasSecurityMeasures ? ' og' : '';
        alertText += hasSecurityMeasures ? securityMeasureText : '';
        alertText += '.';

        this.uuAlertText = alertText;
    }
}
