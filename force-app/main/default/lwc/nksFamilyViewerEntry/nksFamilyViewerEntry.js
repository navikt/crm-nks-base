import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import NAV_ICONS from '@salesforce/resourceUrl/NKS_navIcons';
import nksFamilyViewerEntryHTML from './nksFamilyViewerEntry.html';
import nksFamilyViewerEntryV2HTML from './nksFamilyViewerEntryV2.html';

export default class nksFamilyViewerEntry extends NavigationMixin(LightningElement) {
    @api relation;
    @api useNewDesign;

    render() {
        return this.useNewDesign ? nksFamilyViewerEntryV2HTML : nksFamilyViewerEntryHTML;
    }

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
        if (this.relation.recordType === 'marital') return true;
        return false;
    }

    get isChild() {
        if (this.relation.recordType === 'child') return true;
        return false;
    }

    get isParent() {
        if (this.relation.recordType === 'parent') return true;
        return false;
    }

    get isStillBorn() {
        if (this.relation.recordType === 'stillborn') return true;
        return false;
    }

    get isError() {
        if (
            this.relation.recordType === 'marital' ||
            this.relation.recordType === 'child' ||
            this.relation.recordType === 'parent' ||
            this.relation.recordType === 'stillborn'
        )
            return false;
        return true;
    }

    get getErrorMsg() {
        if (this.relation.name != null) return this.relation.name;
        return '';
    }

    get genderIcon() {
        switch (this.relation.sex) {
            case 'MANN':
                return 'MaleFilled';
            case 'KVINNE':
                return 'FemaleFilled';
            default:
            // do nothing
        }
        return 'NeutralFilled';
    }

    get genderIconNewDesign() {
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
            return 'UnknownCircleFilled';
        }

        if (isMale) {
            return isChild ? 'IconMaleChildFamily' : 'IconMaleFamily';
        }
        if (isFemale) {
            return isChild ? 'IconFemaleChildFamily' : 'IconFemaleFamily';
        }
        return 'UnknownCircleFilled';
    }

    get genderIconNewDesignSrc() {
        return NAV_ICONS + '/' + this.genderIconNewDesign + '.svg#' + this.genderIconNewDesign;
    }

    get genderIconSrc() {
        return NAV_ICONS + '/' + this.genderIcon + '.svg#' + this.genderIcon;
    }

    get genderIconClass() {
        return this.genderIcon;
    }

    get hasEventDate() {
        if (this.relation.eventDate != null) return true;
        return false;
    }

    get getTileName() {
        if (this.relation.unauthorized === true) {
            return this.getName();
        }
        if (this.relation.deceased === true) {
            return this.getName() + ' (Død)';
        }
        return this.getName() + ' (' + this.getAge() + ')';
    }

    get getDateOfDeath() {
        if (this.relation.dateOfDeath != null) {
            return this.relation.dateOfDeath;
        }
        return this.useNewDesign ? 'Ukjent dato' : 'UKJENT DATE';
    }

    get getBirthDate() {
        if (this.relation.birthDate != null) {
            return this.relation.birthDate;
        }
        return this.useNewDesign ? 'Ukjent dato' : 'UKJENT DATE';
    }

    get getSex() {
        if (this.relation.sex != null) {
            return this.relation.sex;
        }
        return this.useNewDesign ? 'Ukjent kjønn' : 'UKJENT KJØNN';
    }

    get getChildText() {
        if (this.relation.unauthorized === true || this.relation.deceased) {
            return '';
        }
        return this.getLiveWithText() + (this.useNewDesign ? '  |  ' : '\n') + this.getResponsibilityChildText();
    }

    get getParentText() {
        if (this.relation.unauthorized === true || this.relation.deceased) {
            return '';
        }
        return this.getLiveWithText() + (this.useNewDesign ? '  |  ' : '\n') + this.getResponsibilityParentText();
    }

    get showCardTile() {
        if (
            this.relation.recordType === 'marital' &&
            (this.relation.role === 'UGIFT' ||
                this.relation.role === 'UOPPGITT' ||
                this.relation.role === 'SKILT' ||
                this.relation.role === 'SKILT_PARTNER')
        )
            return false;
        if (this.relation.recordType === 'stillborn') return false;
        return true;
    }

    get showInfoCard() {
        if (this.relation.unauthorized === true) return false;
        return true;
    }

    get getRole() {
        if (this.relation.recordType === 'stillborn') {
            return this.useNewDesign ? 'Døfødt barn' : 'DØDFØDT BARN';
        }
        if (this.relation.recordType === 'child') {
            if (this.relation.sex === 'MANN') {
                return this.useNewDesign ? 'Sønn' : 'GUTT';
            }
            if (this.relation.sex === 'KVINNE') {
                return this.useNewDesign ? 'Datter' : 'JENTE';
            }
            return this.relation.role;
        }
        if (this.useNewDesign && this.relation.role === 'MOR') {
            return 'Mor';
        }
        if (this.useNewDesign && this.relation.role === 'MEDMOR') {
            return 'Medmor';
        }
        if (this.useNewDesign && this.relation.role === 'FAR') {
            return 'Far';
        }
        if (this.relation.recordType === 'marital') {
            if (this.useNewDesign && this.relation.role === 'GIFT') {
                return 'Gift';
            }
            if (this.useNewDesign && this.relation.role === 'UGIFT') {
                return 'Ugift';
            }
            if (this.relation.role === 'ENKE_ELLER_ENKEMANN') {
                if (this.relation.sex === 'MANN') {
                    return this.useNewDesign ? 'Enke' : 'ENKE';
                }
                if (this.relation.sex === 'KVINNE') {
                    return this.useNewDesign ? 'Enkemann' : 'ENKEMANN';
                }
                return this.useNewDesign ? 'Enke eller Enkemann' : 'ENKE ELLER ENKEMANN';
            }
            if (this.relation.role === 'REGISTRERT_PARTNER') {
                return this.useNewDesign ? 'Registrert partner' : 'REGISTRERT PARTNER';
            }
            if (this.relation.role === 'SEPARERT_PARTNER') {
                return this.useNewDesign ? 'Separert partner' : 'SEPARERT PARTNER';
            }
            if (this.relation.role === 'SKILT_PARTNER') {
                return this.useNewDesign ? 'Skilt partner' : 'SKILT PARTNER';
            }
            if (this.relation.role === 'GJENLEVENDE PARTNER') {
                return this.useNewDesign ? 'Gjenlevende partner' : 'GJENLEVENDE PARTNER';
            }
        }
        return this.relation.role;
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
        let badgesArray = [];
        if (this.relation.employee === true) {
            let badge = {
                name: 'isNavEmployee',
                label: 'Skjermet person (Nav Ansatt)'
            };
            badgesArray.push(badge);
        }
        if (this.relation.confidential === true) {
            if (this.relation.confidentialStatus === 'FORTROLIG') {
                let badge = {
                    name: 'isConfidential',
                    label: 'Skjermet adresse - fortrolig'
                };
                badgesArray.push(badge);
            } else if (this.relation.confidentialStatus === 'STRENGT_FORTROLIG') {
                let badge = {
                    name: 'isConfidential',
                    label: 'Skjermet adresse - strengt fortrolig'
                };
                badgesArray.push(badge);
            } else if (this.relation.confidentialStatus === 'STRENGT_FORTROLIG_UTLAND') {
                let badge = {
                    name: 'isConfidential',
                    label: 'Skjermet adresse - strengt fortrolig'
                };
                badgesArray.push(badge);
            }
        }
        return badgesArray;
    }

    get hasBadges() {
        if (this.relation.employee === true || this.relation.confidential === true) {
            return true;
        }
        return false;
    }

    get personIdentFormatted() {
        if (this.relation.personIdent != null) {
            return this.relation.personIdent.slice(0, 6) + ' ' + this.relation.personIdent.slice(6);
        }
        return '';
    }

    getName() {
        if (this.relation.unauthorized === true) {
            return this.useNewDesign ? 'Skjermet' : 'SKJERMET';
        }
        if (this.relation.name == null) {
            return this.useNewDesign ? 'Ukjent navn' : 'UKJENT NAVN';
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
        if (this.relation.ageString != null) {
            return this.relation.ageString;
        }
        return this.useNewDesign ? 'Ukjent alder' : 'UKJENT ALDER';
    }

    getLiveWithText() {
        if (this.relation.livesWith === true) {
            return 'Bor med bruker';
        }
        return 'Bor ikke med bruker';
    }

    getResponsibilityChildText() {
        if (this.relation.responsible === '' || this.relation.responsible === null) {
            return 'Informasjon om foreldreansvar finnes ikke.';
        }
        if (
            this.relation.responsible === 'far' ||
            this.relation.responsible === 'mor' ||
            this.relation.responsible === 'medmor'
        ) {
            return this.useNewDesign ? 'Foreldreansvar alene' : 'Bruker har foreldreansvar alene.';
        }
        if (this.relation.responsible === 'felles') {
            return this.useNewDesign ? 'Felles foreldreansvar' : 'Bruker har felles foreldreansvar.';
        }
        return this.useNewDesign ? 'Ikke foreldreansvar' : 'Bruker har ikke foreldreansvar.';
    }

    getResponsibilityParentText() {
        if (this.relation.responsible === '' || this.relation.responsible === null) {
            return 'Informasjon om foreldreansvar finnes ikke.';
        }
        if (
            this.relation.responsible === 'far' ||
            this.relation.responsible === 'mor' ||
            this.relation.responsible === 'medmor'
        ) {
            return 'Har foreldreansvar alene.';
        }
        if (this.relation.responsible === 'felles') {
            return 'Har felles foreldreansvar.';
        }
        return 'Har ikke foreldreansvar.';
    }
}
