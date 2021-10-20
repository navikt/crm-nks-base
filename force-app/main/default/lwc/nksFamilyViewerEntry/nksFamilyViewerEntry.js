import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import NAV_ICONS from '@salesforce/resourceUrl/NKS_navIcons';

export default class nksFamilyViewerEntry extends NavigationMixin(LightningElement) {
    @api relation;
    recordPageUrl;

    navigateToSObject(event) {
        event.preventDefault();
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.relation.accountId,
                actionName: 'view'
            }
        });
    }

    connectedCallback() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.relation.accountId,
                actionName: 'view'
            }
        }).then((url) => {
            this.recordPageUrl = url;
        });
    }
    get getUrl(){
        if(this.relation.unauthorized === true || this.relation.confidential === true || this.relation.accountId == null){
            return '#';
        }
        return this.recordPageUrl;
    }
    get isMarital(){
        if(this.relation.recordType === 'marital') return true; 
        return false;
    }
    get isChild(){
        if(this.relation.recordType === 'child') return true;
        return false;
    }
    get isParent(){
        if(this.relation.recordType === 'parent') return true;
        return false;
    }
    get isStillBorn(){
        if(this.relation.recordType === 'stillborn') return true;
        return false;
    }
    get isError(){
        if(this.relation.recordType === 'marital' || this.relation.recordType === 'child' || this.relation.recordType === 'parent' || this.relation.recordType === 'stillborn') return false;
        return true;
    }
    get getErrorMsg(){
        if(this.relation.name != null) return this.relation.name;
        return '';
    }
    get genderIcon() {
        switch (this.relation.sex) {
            case 'MANN':
                return 'MaleFilled';
            case 'KVINNE':
                return 'FemaleFilled';
        }
        return 'NeutralFilled';
    }

    get genderIconSrc() {
        return NAV_ICONS + '/' + this.genderIcon + '.svg#' + this.genderIcon;
    }

    get genderIconClass() {
        return this.genderIcon;
    }
    get hasEventDate(){
        if(this.relation.eventDate != null) return true;
        return false;
    }
    getName(){
        if(this.relation.unauthorized == true){
            return 'SKJERMET';
        }
        if(this.relation.name == null){
            return 'UKJENT NAVN';
        }
        return this.capitalize(this.relation.name);
    }
    capitalize(input){
       return  input
       .toLowerCase()
       .split(' ')
       .map(word => word.charAt(0).toUpperCase() + word.slice(1))
       .join(' ');
    }
    get getTileName(){
        if(this.relation.unauthorized === true){
            return this.getName();
        }
        if(this.relation.deceased === true){
            return this.getName() + ' (Død)';
        }
        return this.getName() + ' (' + this.getAge() + ')';
    }
    get getDateOfDeath(){
        if(this.relation.dateOfDeath != null){
            return this.relation.dateOfDeath;
        }
        return 'UKJENT DATE';
    }
    get getBirthDate(){
        if(this.relation.birthDate != null){
            return this.relation.birthDate;
        }
        return 'UKJENT DATE';
    }
    getAge(){
        if(this.relation.ageString != null){
            return this.relation.ageString;
        }
        return 'UKJENT ALDER'
    }
    hasAccount(){
        if(this.relation.accountId != null){
            return true;
        }
        return false;
    }
    get getSex(){
        if(this.relation.sex != null){
            return this.relation.sex;
        }
        return 'UKJENT KJØNN';
    }
    get getChildText(){
        if(this.relation.unauthorized === true || this.relation.deceased){
            return '';
        }
        return this.getLiveWithText() + this.getResponsibilityChildText();
    }
    get getParentText(){
        if(this.relation.unauthorized === true || this.relation.deceased){
            return '';
        }
        return this.getLiveWithText() + this.getResponsibilityParentText();
    }
    getLiveWithText(){
        if(this.relation.livesWith === true){
            return 'Bor med bruker. ';
        }
        return '';
    }
    getResponsibilityChildText(){
        if(this.relation.responsibility === true){
            return 'Bruker har foreldreansvar.';
        }
        return '';
    }
    getResponsibilityParentText(){
        if(this.relation.responsibility === true){
            return 'Har foreldreansvar.';
        }
        return '';
    }
    get showCardTile(){
        if(this.relation.recordType === 'marital' && 
                (
                    this.relation.role === 'UGIFT' || 
                    this.relation.role === 'UOPPGITT' || 
                    this.relation.role === 'SKILT' ||
                    this.relation.role === 'SKILT_PARTNER'
                )
            ) return false;
        if(this.relation.recordType === 'stillborn') return false;
        return true;
    }
    get showInfoCard(){
        if(this.relation.unauthorized === true) return false;
        return true;
    }
    get showUrl(){
        if(this.relation.unauthorized === true) return false;
        if(this.relation.confidential === true) return false;
        if(this.relation.accountId == null) return false;
        return this.hasAccount();
    }
    get getRole(){
        if(this.relation.recordType === 'stillborn'){
            return 'DØDFØDT BARN';
        }
        if(this.relation.recordType ==='child'){
            if(this.relation.sex === 'MANN'){
                return 'GUTT';
            }
            if(this.relation.sex === 'KVINNE'){
                return 'JENTE'
            }
            return this.relation.role;
        }
        if(this.relation.recordType === 'marital'){
            if(this.relation.role === 'ENKE_ELLER_ENKEMANN'){
                if(this.relation.sex === 'MANN'){
                    return 'ENKE';
                }
                if(this.relation.sex === 'KVINNE'){
                    return 'ENKEMANN';
                }
                return 'ENKE ELLER ENKEMANN';
            }
            if(this.relation.role === 'REGISTRERT_PARTNER'){
                return 'REGISTRERT PARTNER';
            }
            if(this.relation.role === 'SEPARERT_PARTNER'){
                return 'SEPARERT PARTNER';
            }
            if(this.relation.role === 'SKILT_PARTNER'){
                return 'SKILT PARTNER';
            }
            if(this.relation.role === 'GJENLEVENDE PARTNER'){
                return 'GJENLEVENDE PARTNER';
            }
        }
        return this.relation.role;
    }
}
