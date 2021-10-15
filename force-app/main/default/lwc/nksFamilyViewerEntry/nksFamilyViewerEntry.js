import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

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
    get isError(){
        if(this.relation.recordType === 'marital' || this.relation.recordType === 'child' || this.relation.recordType === 'parent') return false;
        return true;
    }
    get getColor(){
        if(this.relation.sex == 'MANN') return 'blue';
        if(this.relation.sex == 'KVINNE') return 'pink';
        return null;
    }
    get hasEventDate(){
        if(this.relation.eventDate != null) return true;
        return false;
    }
    getName(){
        if(this.relation.unauthorized == true){
            return 'IKKE TILGJENGELIG';
        }
        if(this.relation.name == null){
            return 'UKJENT NAVN';
        }
        return this.relation.name;
    }
    get getTileName(){
        if(this.relation.unauthorized === true){
            return this.getName();
        }
        if(this.relation.deceased === true){
            return this.getName() + '(Død)';
        }
        return this.getName() + '(' + this.getAge() + ')';
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
        if(this.relation.age != null){
            return this.relation.age;
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
            return ' - Bor med bruker.';
        }
        return '';
    }
    getResponsibilityChildText(){
        if(this.relation.responsibility === true){
            return ' - Bruker har foreldreansvar.';
        }
        return '';
    }
    getResponsibilityParentText(){
        if(this.relation.responsibility === true){
            return ' - Har foreldreansvar.';
        }
        return '';
    }
    get showCard(){
        if(this.relation.unauthorized) return false;
        if  (this.relation.recordType === 'marital' && 
                (this.relation.role === 'UGIFT' || this.relation.role === 'UOPPGITT')
            ) return false;
        return true;
    }
}
