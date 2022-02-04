import { LightningElement, api } from 'lwc';

export default class CrmRelatedListItem extends LightningElement {
    @api record;
    @api usedFields;
    @api relatedObjectApiName;
    @api index;
    @api objectName;

    get number() {
        return this.index + 1;
    }
}
