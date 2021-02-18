import { LightningElement, api } from 'lwc';
import checkAccess from '@salesforce/apex/NKS_AccessErrorController.checkAccess';

export default class NksAccessErrorMessage extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api text;

    connectedCallback() {
        this.checkAccess();
    }

    checkAccess() {
        checkAccess({
            recordId: this.recordId,
            objectApiName: this.objectApiName
        })
            .then((data) => {
                this.text = data && data.length > 0 ? data : null;
            })
            .catch((error) => {
                console.log('An error occurred: ' + JSON.stringify(error, null, 2));
            });
    }
}
