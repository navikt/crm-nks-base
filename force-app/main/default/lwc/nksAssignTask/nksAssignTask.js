import { LightningElement, track, api, wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import getUnits from '@salesforce/apex/NKS_NavUnitsController.getUnits';

export default class NksAssignTask extends LightningElement {
    _queueId;
    _selectedTheme;
    _selectedSubTheme;
    _createTask;
    _dueDate;
    _additionalComments;
    _conversationNote;

    @track units;
    @track defaultQueueId = this.queueId;
    @track themeValue;

    @wire(getUnits)
    wiredValues({ data, error }) {
        if (data) {
            this.units = JSON.parse(data);
        } else if (error) {
            console.log(error);
        }
    }

    @api
    get queueId() {
        return this._queueId;
    }

    set queueId(value) {
        this._queueId = value;
    }

    @api
    get selectedTheme() {
        return this._selectedTheme;
    }

    set selectedTheme(value) {
        this._selectedTheme = value;
    }

    @api
    get selectedSubTheme() {
        return this._selectedSubTheme;
    }

    set selectedSubTheme(value) {
        this._selectedSubTheme = value;
    }

    @api
    get createTask() {
        return this._createTask;
    }

    set createTask(value) {
        this._createTask = value;
    }

    @api
    get dueDate() {
        return this._dueDate;
    }

    set dueDate(value) {
        this._dueDate = value;
    }

    @api
    get additionalComments() {
        return this._additionalComments;
    }

    set additionalComments(value) {
        this._additionalComments = value;
    }

    @api
    get conversationNote() {
        return this._conversationNote;
    }

    set conversationNote(value) {
        this._conversationNote = value;
    }

    handleUnitChange(event) {
        this._queueId = event.detail.value;
        const attributeChangeEvent = new FlowAttributeChangeEvent('unit', this.queueId);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleSubThemeChange(event) {
        this._selectedSubTheme = event.detail;
        if (this.selectedSubTheme === 'Tiltaksøkonomi') {
            this.template.querySelector('[data-id="toggle"]').className = 'hide';
        } else if (this.selectedSubTheme === 'Lønnskompensasjon') {
            this.template.querySelector('[data-id="toggle"]').className = 'hide';
        } else if (this.selectedSubTheme === 'Generell sykefraværsoppfølging') {
            this.template.querySelector('[data-id="toggle"]').className = 'hide';
        } else {
            this.template.querySelector('[data-id="toggle"]').className = 'show';
        }
        const attributeChangeEvent = new FlowAttributeChangeEvent('sub-theme', this.selectedSubTheme);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleThemeChange(event) {
        this._selectedTheme = event.detail;
        const attributeChangeEvent = new FlowAttributeChangeEvent('theme', this.selectedTheme);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleToggleChange(event) {
        this._createTask = event.target.checked;
        const attributeChangeEvent = new FlowAttributeChangeEvent('create-task', this.createTask);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleDueDateChange(event) {
        this._dueDate = event.detail.value;
        const attributeChangeEvent = new FlowAttributeChangeEvent('due-date', this.dueDate);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleAdditionalChange(event) {
        this._additionalComments = event.detail.value;
        const attributeChangeEvent = new FlowAttributeChangeEvent('additional-commnets', this.additionalComment);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleConversationNoteChange(event) {
        this._conversationNote = event.detail;
        const attributeChangeEvent = new FlowAttributeChangeEvent('conversation-note', this.conversationNote);
        this.dispatchEvent(attributeChangeEvent);
    }
}
