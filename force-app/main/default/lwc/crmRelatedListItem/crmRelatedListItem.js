import { LightningElement, api } from 'lwc';

export default class CrmRelatedListItem extends LightningElement {
    @api record;
    @api usedFields;
    @api relatedObjectApiName;
}
