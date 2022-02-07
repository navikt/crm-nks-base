import { getFieldDisplayValue } from 'lightning/uiRecordApi';
import { LightningElement, api } from 'lwc';

export default class CrmRelatedListItem extends LightningElement {
    @api record;
    @api usedFields;
    @api relatedObjectApiName;
    @api index;
    @api objectName;
    @api dateField;
}
