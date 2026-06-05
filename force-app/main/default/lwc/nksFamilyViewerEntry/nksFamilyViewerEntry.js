import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import NAV_ICONS from '@salesforce/resourceUrl/NKS_navIcons';

export default class nksFamilyViewerEntry extends NavigationMixin(LightningElement) {
    @api relation;

    handleCopyIdent() {
        var hiddenInput = document.createElement('input');
        var successful = false;
        var msg = '';
        hiddenInput.value = this.relation.personIdent;
        document.body.appendChild(hiddenInput);
        hiddenInput.select();
        try {
            // eslint-disable-next-line @locker/locker/distorted-document-exec-command
            successful = document.execCommand('copy');
            msg = successful ? 'successful' : 'unsuccessful';
            console.log('Copying text command was ' + msg);
        } catch (err) {
            console.log('Oops, unable to copy');
        }

        document.body.removeChild(hiddenInput);
    }

    get isMarital() {
        return this.relation.recordType === 'marital';
    }

    get isChild() {
        return this.relation.recordType === 'child';
    }

    get isParent() {
        return this.relation.recordType === 'parent';
    }

    get isStillBorn() {
        return this.relation.recordType === 'stillborn';
    }

    get isError() {
        return !['marital', 'child', 'parent', 'stillborn'].includes(this.relation.recordType);
    }

    get getErrorMsg() {
        return this.relation.name ?? '';
    }

    get genderIcon() {
        const isChild = this.getRole === 'Sønn' || this.getRole === 'Datter';
        const isMale = this.relation.sex === 'MANN';
        const isFemale = this.relation.sex === 'KVINNE';

        if (this.relation.recordType === 'stillborn') {
            return 'IconStillbornFamily';
        }

        if (this.relation.deceased) {
            if (isMale) {
                return isChild ? 'IconMaleChildDeceasedFamily' : 'IconMaleDeceasedFamily';
            }
            if (isFemale) {
                return isChild ? 'IconFemaleChildDeceasedFamily' : 'IconFemaleDeceasedFamily';
            }
        } else {
            if (isMale) {
                return isChild ? 'IconMaleChildFamily' : 'IconMaleFamily';
            }
            if (isFemale) {
                return isChild ? 'IconFemaleChildFamily' : 'IconFemaleFamily';
            }
        }
        return 'UnknownCircleFilled';
    }

    get genderIconSrc() {
        return NAV_ICONS + '/' + this.genderIcon + '.svg#' + this.genderIcon;
    }

    get hasEventDate() {
        return this.relation.eventDate != null;
    }

    get getTileName() {
        if (this.relation.unauthorized) {
            return this.getName();
        }
        if (this.relation.deceased) {
            return this.getName() + ' (Død)';
        }
        return this.getName() + ' (' + this.getAge() + ')';
    }

    get getDateOfDeath() {
        return this.relation.dateOfDeath ?? 'Ukjent dato';
    }

    get getBirthDate() {
        return this.relation.birthDate ?? 'Ukjent dato';
    }

    get getSex() {
        return this.relation.sex ?? 'Ukjent kjønn';
    }

    get getChildText() {
        return this.relation.unauthorized || this.relation.deceased
            ? ''
            : this.getLiveWithText + '\n' + this.getResponsibilityChildText;
    }

    get getParentText() {
        return this.relation.unauthorized || this.relation.deceased
            ? ''
            : this.getLiveWithText + '\n' + this.getResponsibilityParentText;
    }

    get showCardTile() {
        if (
            this.relation.recordType === 'marital' &&
            (this.relation.role === 'UGIFT' ||
                this.relation.role === 'UOPPGITT' ||
                this.relation.role === 'SKILT' ||
                this.relation.role === 'SKILT_PARTNER')
        ) {
            return false;
        }
        return this.relation.recordType !== 'stillborn';
    }

    get showInfoCard() {
        return !this.relation.unauthorized;
    }

    get getRole() {
        const { recordType, sex, role } = this.relation;

        if (recordType === 'stillborn') {
            return 'Dødfødt barn';
        }

        if (recordType === 'child') {
            if (sex === 'MANN') return 'Sønn';
            if (sex === 'KVINNE') return 'Datter';
            return role;
        }

        if (recordType === 'marital' && role === 'ENKE_ELLER_ENKEMANN') {
            if (sex === 'MANN') return 'Enke';
            if (sex === 'KVINNE') return 'Enkemann';
            return 'Enke eller Enkemann';
        }

        const roles = {
            MOR: 'Mor',
            MEDMOR: 'Medmor',
            FAR: 'Far',
            GIFT: 'Gift',
            UGIFT: 'Ugift',
            REGISTRERT_PARTNER: 'Registrert partner',
            SEPARERT_PARTNER: 'Separert partner',
            SKILT_PARTNER: 'Skilt partner',
            'GJENLEVENDE PARTNER': 'Gjenlevende partner'
        };

        if (roles[role]) {
            return roles[role];
        }
        return role;
    }

    get uuAlertText() {
        let alertText = '';

        let navEmployeeText = ' er egen ansatt';
        let isConfidentialText = ' skjermet';

        alertText += 'Bruker';
        alertText += this.relation.employee ? navEmployeeText : '';
        if (this.relation.employee && this.relation.confidential) {
            alertText += ' og';
        } else {
            if (this.relation.confidential) {
                alertText += ' er';
            } else {
                alertText += '';
            }
        }
        alertText += this.relation.confidential ? isConfidentialText : '';
        alertText += '.';

        return alertText;
    }

    get badges() {
        const badgesArray = [];

        if (this.relation.employee) {
            badgesArray.push({
                name: 'isNavEmployee',
                label: 'Skjermet person (Nav Ansatt)'
            });
        }

        if (this.relation.confidential) {
            const confidentialLabels = {
                FORTROLIG: 'Skjermet adresse - fortrolig',
                STRENGT_FORTROLIG: 'Skjermet adresse - strengt fortrolig',
                STRENGT_FORTROLIG_UTLAND: 'Skjermet adresse - strengt fortrolig'
            };

            const label = confidentialLabels[this.relation.confidentialStatus];
            if (label) {
                badgesArray.push({
                    name: 'isConfidential',
                    label
                });
            }
        }
        return badgesArray;
    }

    get hasBadges() {
        return this.relation.employee || this.relation.confidential;
    }

    get personIdentFormatted() {
        return this.relation.personIdent
            ? this.relation.personIdent.slice(0, 6) + ' ' + this.relation.personIdent.slice(6)
            : '';
    }

    getName() {
        if (this.relation.unauthorized) {
            return 'Skjermet';
        }
        if (this.relation.name == null) {
            return 'Ukjent navn';
        }
        return this.capitalize(this.relation.name);
    }

    capitalize(input) {
        return input
            .toLowerCase()
            .split(' ')
            .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');
    }

    getAge() {
        return this.relation.ageString ?? 'Ukjent alder';
    }

    get getLiveWithText() {
        return this.relation.livesWith ? 'Bor med bruker' : 'Bor ikke med bruker';
    }

    get getResponsibilityChildText() {
        if (this.relation.responsible === '' || this.relation.responsible === null) {
            return 'Informasjon om foreldreansvar finnes ikke.';
        }
        if (
            this.relation.responsible === 'far' ||
            this.relation.responsible === 'mor' ||
            this.relation.responsible === 'medmor'
        ) {
            return 'Foreldreansvar alene';
        }
        if (this.relation.responsible === 'felles') {
            return 'Felles foreldreansvar';
        }
        return 'Ikke foreldreansvar';
    }

    get getResponsibilityParentText() {
        if (this.relation.responsible === '' || this.relation.responsible === null) {
            return 'Informasjon om foreldreansvar finnes ikke.';
        }
        if (
            this.relation.responsible === 'far' ||
            this.relation.responsible === 'mor' ||
            this.relation.responsible === 'medmor'
        ) {
            return 'Foreldreansvar alene';
        }
        if (this.relation.responsible === 'felles') {
            return 'Felles foreldreansvar';
        }
        return 'Ikke foreldreansvar';
    }
}
