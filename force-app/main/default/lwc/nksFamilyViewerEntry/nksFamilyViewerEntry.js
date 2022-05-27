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
        return 'UKJENT DATE';
    }

    get getBirthDate() {
        if (this.relation.birthDate != null) {
            return this.relation.birthDate;
        }
        return 'UKJENT DATE';
    }

    get getSex() {
        if (this.relation.sex != null) {
            return this.relation.sex;
        }
        return 'UKJENT KJØNN';
    }

    get getChildText() {
        if (this.relation.unauthorized === true || this.relation.deceased) {
            return '';
        }
        return this.getLiveWithText() + this.getResponsibilityChildText();
    }

    get getParentText() {
        if (this.relation.unauthorized === true || this.relation.deceased) {
            return '';
        }
        return this.getLiveWithText() + this.getResponsibilityParentText();
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
            return 'DØDFØDT BARN';
        }
        if (this.relation.recordType === 'child') {
            if (this.relation.sex === 'MANN') {
                return 'GUTT';
            }
            if (this.relation.sex === 'KVINNE') {
                return 'JENTE';
            }
            return this.relation.role;
        }
        if (this.relation.recordType === 'marital') {
            if (this.relation.role === 'ENKE_ELLER_ENKEMANN') {
                if (this.relation.sex === 'MANN') {
                    return 'ENKE';
                }
                if (this.relation.sex === 'KVINNE') {
                    return 'ENKEMANN';
                }
                return 'ENKE ELLER ENKEMANN';
            }
            if (this.relation.role === 'REGISTRERT_PARTNER') {
                return 'REGISTRERT PARTNER';
            }
            if (this.relation.role === 'SEPARERT_PARTNER') {
                return 'SEPARERT PARTNER';
            }
            if (this.relation.role === 'SKILT_PARTNER') {
                return 'SKILT PARTNER';
            }
            if (this.relation.role === 'GJENLEVENDE PARTNER') {
                return 'GJENLEVENDE PARTNER';
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
                label: 'Skjermet person (NAV Ansatt)'
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

    getName() {
        if (this.relation.unauthorized === true) {
            return 'SKJERMET';
        }
        if (this.relation.name == null) {
            return 'UKJENT NAVN';
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
        return 'UKJENT ALDER';
    }

    getLiveWithText() {
        var res = '';
        if (this.relation.livesWith === true) {
            res += 'Bor med bruker.';
        } else {
            res += 'Bor ikke med bruker.';
        }
        return res;
    }

    getResponsibilityChildText() {
        var res = '';
        if (
            this.relation.responsible === 'far' ||
            this.relation.responsible === 'mor' ||
            this.relation.responsible === 'medmor'
        ) {
            res += 'Bruker har foreldreansvar alene.';
        } else if (this.relation.responsible === 'felles') {
            res += 'Bruker har felles foreldreansvar.';
        } else {
            res += 'Bruker har ikke foreldreansvar.';
        }
        return res;
    }

    getResponsibilityParentText() {
        if (this.relation.responsibility === true) {
            return 'Har foreldreansvar.';
        }
        return '';
    }
}
