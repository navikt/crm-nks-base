import { LightningElement, api } from 'lwc';
import hasPermission from '@salesforce/customPermission/Manage_Traffic_Updates';
import updateNksStatus from '@salesforce/apex/NKS_HomePageController.updateNksStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class NksHomePageHighlightPanelBadge extends LightningElement {
    @api badgeLabel;
    @api showContent = false;

    _recordId;
    _recordInfo;
    badgeIcon = 'utility:success';
    className = 'slds-badge slds-theme_success custom-badge';
    isEditing = false;
    draft;

    connectedCallback() {
        this.updateBadgeClass();
    }

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.updateBadgeClass();
        }
    }

    @api
    get recordInfo() {
        return this._recordInfo;
    }

    set recordInfo(value) {
        this._recordInfo = value;
        this.draft = value;
        this.updateBadgeClass();
    }

    get ariaExpanded() {
        return this.showContent.toString();
    }

    get isEditable() {
        return hasPermission;
    }

    updateBadgeClass() {
        let baseClass = 'slds-badge custom-badge';
        if (!this.recordId) {
            this.className = `${baseClass} slds-theme_success disabled-badge`;
            this.badgeIcon = 'utility:success';
        } else if (this.recordInfo) {
            this.className = `${baseClass} slds-theme_error cursor-pointer`;
            this.badgeIcon = 'utility:error';
        } else {
            this.className = `${baseClass} slds-theme_success ${hasPermission ? 'cursor-pointer' : ''}`.trim();
            this.badgeIcon = 'utility:success';
        }
    }

    toggleDropdown() {
        if (!(this.recordInfo || this.isEditable)) {
            return;
        }
        this.dispatchEvent(
            new CustomEvent('badgeclick', {
                detail: { label: this.badgeLabel }
            })
        );
    }

    handleTextChange(event) {
        this.draft = event.target.value;
    }

    enableEditing() {
        this.isEditing = true;
    }

    handleSave() {
        this.isEditing = false;
        this.updateRecord();
    }

    handleCancel() {
        this.isEditing = false;
        this.draft = this.recordInfo;
    }

    updateRecord() {
        if (!this.recordId) {
            this.showError('Missing required data.');
            return;
        }

        const fields = {
            Id: this.recordId,
            NKS_Information__c: this.draft
        };

        updateNksStatus({ fields })
            .then(() => {
                this._recordInfo = this.draft;
                this.updateBadgeClass();
                this.showSuccess('Record updated successfully');
            })
            .catch((error) => {
                console.error('Error updating record:', error);
                this.showError('Error updating record: ' + error.body.message);
            });
    }

    showSuccess(message) {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }

    showError(message) {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        });
        this.dispatchEvent(evt);
    }
}
