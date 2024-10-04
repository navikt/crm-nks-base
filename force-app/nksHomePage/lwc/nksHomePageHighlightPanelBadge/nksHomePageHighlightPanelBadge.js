import { LightningElement, api } from 'lwc';
import hasPermission from '@salesforce/customPermission/Manage_Traffic_Updates';
import updateNksStatus from '@salesforce/apex/NKS_HomePageController.updateNksStatus';

export default class NksHomePageHighlightPanelBadge extends LightningElement {
    @api badgeLabel;
    @api showContent = false;

    _recordId;
    _recordInfo;
    badgeIcon = 'utility:success';
    className = 'custom-badge slds-theme_success';
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
        return hasPermission;
        //return false;
    }

    updateBadgeClass() {
        this.className = 'custom-badge slds-theme_success';
        this.badgeIcon = 'utility:success';

        if (!this.recordId) {
            this.className += ' disabled-badge';
        } else {
            this.className = this.className.replace('disabled-badge', '').trim();
        }

        if (hasPermission && !this.className.includes('cursor-pointer')) {
            this.className += ' cursor-pointer';
        }

        if (this.recordInfo) {
            this.className = 'custom-badge slds-theme_error cursor-pointer';
            this.badgeIcon = 'utility:error';
        } else {
            this.className = 'custom-badge slds-theme_success cursor-pointer';
            this.badgeIcon = 'utility:success';
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
