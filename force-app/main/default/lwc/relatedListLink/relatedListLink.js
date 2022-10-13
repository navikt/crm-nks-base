import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';

export default class RelatedListLink extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api label;
    @api relatedList;
    @api relationshipField;

    wireFields;
    relatedListUrl;

    connectedCallback() {
        this.wireFields = this.relationshipField ? [this.relationshipField] : [this.objectApiName + '.Id'];
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$wireFields' })
    wiredLink({ data, error }) {
        if (error) {
            console.log(error);
        }
        if (data) {
            const value = this.relationshipField ? getFieldValue(data, this.relationshipField) : this.recordId;
            this.pageReference = {
                type: 'standard__recordRelationshipPage',
                attributes: {
                    recordId: value,
                    relationshipApiName: this.relatedList,
                    actionName: 'view'
                }
            };
            this[NavigationMixin.GenerateUrl](this.pageReference)
                .then((url) => (this.relatedListUrl = url))
                .catch((a) => console.log(a));
        }
    }

    handleClick(event) {
        this[NavigationMixin.Navigate](this.pageReference);
        event.preventDefault();
    }
}
