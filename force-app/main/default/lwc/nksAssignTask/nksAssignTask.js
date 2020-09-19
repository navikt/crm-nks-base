import { LightningElement, track, api, wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import getUnits from "@salesforce/apex/NKS_NavUnitsController.getUnits";

export default class NksAssignTask extends LightningElement {
    @api queueId;
    @track units;
    @track queueId;

    @wire(getUnits)
    wiredValues({ data, error }) {
        if (data) {
            this.units = JSON.parse(data);
        } else if (error) {
            window.console.log('Error in wiredValues');
            window.console.log(error);
        }
    }

    handleUnitChange(event) {
        this.queueId = event.detail.value;
    }
}