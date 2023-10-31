import { LightningElement, api } from 'lwc';
import DETAILS_TAB_LABEL from '@salesforce/label/c.NKS_Details_Tab_Label';
import COMMUNICATION_TAB_LABEL from '@salesforce/label/c.NKS_Communication_Tab_Label';
import TASKS_TAB_LABEL from '@salesforce/label/c.NKS_Tasks_Tab_Label';
import DOCUMENTS_TAB_LABEL from '@salesforce/label/c.NKS_Documents_Tab_Label';
import PAYOUT_TAB_LABEL from '@salesforce/label/c.NKS_Payout_Tab_Label';
import CASES_TAB_LABEL from '@salesforce/label/c.NKS_Cases_Tab_Label';

export default class NksPersonTab extends LightningElement {
    @api recordId;
    @api objectApiName;

    details = DETAILS_TAB_LABEL;
    communication = COMMUNICATION_TAB_LABEL;
    tasks = TASKS_TAB_LABEL;
    documents = DOCUMENTS_TAB_LABEL;
    payout = PAYOUT_TAB_LABEL;
    cases = CASES_TAB_LABEL;

    // TODO: Add logic for both account and case
    // TODO: Use labels for english/norwegian

    handleTabClick(event) {
        console.log('First');
        const tabContent2 = `Tab ${event.target.label} is now active`;
        console.log(tabContent2);
    }

    get tabConditional() {
        // TODO: Add conditions for show any information, mostly access
        return true;
    }

    get flyttingConditional() {
        // TODO: Add conditions for hiding flytting, mostly access
        return true;
    }

    receiveHeading() {
        console.log('Cwazy cupcake');
    }

    updateLoadMore() {
        console.log('What');
    }
}
