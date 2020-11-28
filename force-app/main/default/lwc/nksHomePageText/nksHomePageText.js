import { LightningElement, api } from 'lwc';
import getField from '@salesforce/apex/NKS_RecordFieldController.getField';

export default class NksHomePageText extends LightningElement {
    @api cardTitle;
    @api iconName;
    @api type;

    @api text;

    connectedCallback() {
        this.getField();
    }

    getField() {
        getField({
            type: this.type
        })
            .then(data => {
                this.text = (data && data.length > 0) ? data : null;
            })
            .catch(error => {
                console.log('An error occurred: ' + JSON.stringify(error, null, 2));
            });
    }

    get icon() {
        let nameString = null;
        if (this.iconName && this.iconName != '') nameString = this.iconName;

        return nameString;
    }

}





