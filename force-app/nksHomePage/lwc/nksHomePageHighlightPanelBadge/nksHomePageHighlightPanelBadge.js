import { LightningElement, api } from 'lwc';
import hasPermission from '@salesforce/customPermission/Manage_Traffic_Updates';
import updateNksStatus from '@salesforce/apex/NKS_HomePageController.updateNksStatus';

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
        if (this.recordId) {
            this.updateBadgeClass();
        }
    }

    @api
    get recordInfo() {
        return this._recordInfo;
    }

    set recordInfo(value) {
        this._recordInfo = value;
        if (this.recordInfo) {
            this.draft = this.recordInfo;
        }
        this.updateBadgeClass();
    }

    get ariaExpanded() {
        return this.showContent.toString();
    }

    get isEditable() {
        return hasPermission || false;
    }

    updateBadgeClass() {
        this.className = 'slds-badge slds-theme_success custom-badge';
        this.badgeIcon = 'utility:success';

        if (!this.recordId) {
            this.className += ' disabled-badge';
        } else {
            this.className = this.className.replace('disabled-badge', '').trim();
        }

        if (hasPermission) {
            this.className += ' cursor-pointer';
        }

        if (this.recordInfo) {
            this.className = 'slds-badge slds-theme_error cursor-pointer custom-badge';
            this.badgeIcon = 'utility:error';
        }
    }

    toggleDropdown() {
        if (this.recordInfo || this.isEditable) {
            const clickEvent = new CustomEvent('badgeclick', {
                detail: { label: this.badgeLabel }
            });
            this.dispatchEvent(clickEvent);
        }
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
        const fields = {
            Id: this.recordId,
            NKS_Information__c: this.draft
        };

        updateNksStatus({ fields })
            .then(() => {
                this._recordInfo = this.draft;
                this.updateBadgeClass();
            })
            .catch((error) => {
                console.error('Error updating record:', error);
            });
    }
}
