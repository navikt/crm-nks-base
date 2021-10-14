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
    getUrl(){
        if(this.relation.unauthorized === true || this.relation.confidential === true || this.relation.accountId == null){
            return '#';
        }
        return this.recordPageUrl;
    }
    isMarital(){
        if(this.relation.recordType === 'marital') return true; 
        return false;
    }
    isChild(){
        if(this.relation.recordType === 'child') return true;
        return false;
    }
    isParent(){
        if(this.relation.recordType === 'parent') return true;
        return false;
    }
    isError(){
        if(isMarital() || isChild() || isParent()) return false;
        return true;
    }
    getColor(){
        if(this.relation.sex == 'MANN') return 'blue';
        if(this.relation.sex == 'KVINNE') return 'pink';
        return null;
    }
    hasEventDate(){
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
    getTileName(){
        if(this.relation.unauthorized === true){
            return this.getName();
        }
        if(this.relation.deceased === true){
            return this.getName() + '(Død)';
        }
        return this.getName() + '(' + this.getAge() + ')';
    }
    getDateOfDeath(){
        if(this.relation.dateOfDeath != null){
            return this.relation.dateOfDeath;
        }
        return 'UKJENT DATE';
    }
    getBirthDate(){
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
    getSex(){
        if(this.relation.sex != null){
            return this.relation.sex;
        }
        return 'UKJENT KJØNN';
    }
    getChildText(){
        if(this.relation.unauthorized === true || this.relation.deceased){
            return '';
        }
        return this.getLiveWithText() + this.getResponsibilityChildText();
    }
    getParentText(){
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
}
