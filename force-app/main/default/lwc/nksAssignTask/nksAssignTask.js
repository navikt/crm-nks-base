import { LightningElement, track, api, wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import getUnits from "@salesforce/apex/NKS_NavUnitsController.getUnits";

export default class NksAssignTask extends LightningElement {
    @api queueId;
    @api selectedTheme;
    @api selectedSubTheme;
    @api createTask;
    @api dueDate;
    @api additionalComments;
    @track units;
    @track queueId;


    @wire(getUnits)
    wiredValues({ data, error }) {
        if (data) {
            this.units = JSON.parse(data);
        } else if (error) {
        }
    }

    handleUnitChange(event) {
        this.queueId = event.detail.value;
        const attributeChangeEvent = new FlowAttributeChangeEvent('unit', this.queueId);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleSubThemeChange(event) {
        this.selectedSubTheme = event.detail;
        if (this.selectedSubTheme == "Tiltaksøkonomi") {
            this.template.querySelector('[data-id="toggle"]').className = 'hide';
        }
        else {
            this.template.querySelector('[data-id="toggle"]').className = 'show';
        }
        const attributeChangeEvent = new FlowAttributeChangeEvent('sub-theme', this.selectedSubTheme);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleThemeChange(event) {
        this.selectedTheme = event.detail;
        this.selectedSubTheme = null;
        const attributeChangeEvent = new FlowAttributeChangeEvent('theme', this.selectedTheme);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleToggleChange(event) {
        this.createTask = event.target.checked;
        if (this.createTask == true) {
            this.template.querySelector('[data-id="task"]').className = 'show';
        } else {
            this.template.querySelector('[data-id="task"]').className = 'hide';
        }
        const attributeChangeEvent = new FlowAttributeChangeEvent('create-task', this.createTask);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleDueDateChange(event) {
        this.dueDate = event.detail.value;
        const attributeChangeEvent = new FlowAttributeChangeEvent('due-date', this.dueDate);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleAdditionalChange(event) {
        this.additionalComments = event.detail.value;
        const attributeChangeEvent = new FlowAttributeChangeEvent('additional-commnets', this.additionalComment);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleConversationNoteChange(event) {
        const attributeChangeEvent = new FlowAttributeChangeEvent('comments', event.detail);
        this.dispatchEvent(attributeChangeEvent);
    }
}