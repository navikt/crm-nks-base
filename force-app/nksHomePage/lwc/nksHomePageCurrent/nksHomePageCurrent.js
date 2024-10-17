import { LightningElement, api, wire } from 'lwc';
import hasPermission from '@salesforce/customPermission/NKS_Communication';
import createNksCurrent from '@salesforce/apex/NKS_HomePageController.createNksCurrent';
import getNksCurrents from '@salesforce/apex/NKS_HomePageController.getNksCurrents';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

export default class NksHomePageCurrent extends NavigationMixin(LightningElement) {
    @api cardLabel;

    showDropdown = false;
    records = [];
    showModal = false;
    wiredRecords;
    title;
    url;

    @wire(getNksCurrents)
    wiredCurrents({ error, data }) {
        this.wiredRecords = { error, data };
        if (data) {
            this.records = data;
        } else if (error) {
            console.error(`Problem getting currents: ${error}`);
        }
    }

    get buttonClass() {
        let btnClass = 'slds-dropdown-trigger slds-dropdown-trigger_click';
        return `${btnClass}  ${this.showDropdown ? ' slds-is-open' : ' slds-is-close'}`;
    }

    get hasRecords() {
        return this.records.length > 0;
    }

    get modalClass() {
        let modalClass = 'slds-modal slds-modal_prompt';
        return `${modalClass} ${this.showModal ? ' slds-fade-in-open' : ' slds-fade-in-close'}`;
    }

    get hasPermission() {
        return hasPermission;
    }

    toggleDropdown() {
        this.showDropdown = !this.showDropdown;
    }

    refreshData() {
        if (this.wiredRecords) {
            refreshApex(this.wiredRecords);
        }
    }

    handleAddLink() {
        this.showModal = true;
        this.showDropdown = false;
    }

    handleCancel() {
        this.showModal = false;
        this.showDropdown = false;
    }

    handleInputChange(event) {
        this[event.target.name] = event.target.value;
    }

    handleSubmit(event) {
        event.preventDefault();

        createNksCurrent({ title: this.title, URL: this.url })
            .then(() => {
                this.refreshData();
            })
            .catch((error) => {
                const errorMessage = error.body ? error.body.message : 'Unknown error occurred';
                console.error(`Error creating NKS current: ${errorMessage}`);
            });

        this.showModal = false;
        this.showDropdown = false;
    }

    navigateToListView() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'NKS_Announcement__c',
                actionName: 'list'
            },
            state: {
                filterName: 'Current_From_NAV'
            }
        });
        this.showDropdown = false;
    }
}
