import { LightningElement, api } from 'lwc';

export default class NksRelatedListItem extends LightningElement {
    @api record;
    @api usedFields;
    @api rowIndex;
    @api relatedObjectApiName;
}
