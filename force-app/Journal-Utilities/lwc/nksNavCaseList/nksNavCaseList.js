import { LightningElement, api } from 'lwc';

//##LABEL IMPORTS
import COL_CREATED_DATE from '@salesforce/label/c.NKS_Journal_Case_List_Col_Created_Date';
import COL_CASE_ID from '@salesforce/label/c.NKS_Journal_Case_List_Col_Case_Id';

export default class NksNavCaseList extends LightningElement {
    labels = {
        COL_CREATED_DATE,
        COL_CASE_ID
    };

    @api themeName;
    @api cases;
    @api showCases = false;

    toggleCases(event) {
        this.showCases = !this.showCases;
    }

    checkKeyPress(event) {
        if (event.key === 'Enter') this.toggleCases(event);
    }

    handleCaseSelected(event) {
        let selectedCase = event.detail.selectedCase;
        //Passing event on to the parent
        const caseSelectedEvent = new CustomEvent('caseselected', {
            detail: { selectedCase }
        });
        this.dispatchEvent(caseSelectedEvent);
    }

    //Method called from parent when handling the caseselected event
    @api
    setSelectedNavCase(selectedNavCaseId) {
        let caseItems = this.template.querySelectorAll('c-nks-nav-case-item');
        caseItems.forEach((caseItem) => {
            caseItem.selected = caseItem.navCase.fagsakId == selectedNavCaseId ? true : false;
        });
    }

    get chevronIcon() {
        return this.showCases === false ? 'utility:chevronright' : 'utility:chevrondown';
    }

    get sortedCases() {
        let sortedCases = [...this.cases];
        sortedCases.sort((a, b) => {
            let longA = new Date(a.datoOpprettet).getTime();
            let longB = new Date(b.datoOpprettet).getTime();
            return longB - longA;
        });
        return sortedCases;
    }
}
