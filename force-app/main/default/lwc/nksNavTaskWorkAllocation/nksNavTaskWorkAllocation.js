import { LightningElement, api, track, wire } from 'lwc';
import nksSingleValueUpdate from '@salesforce/messageChannel/nksSingleValueUpdate__c';
import getWorkAllocations from '@salesforce/apex/NKSNavTaskWorkAllocationController.getWorkAllocations';

import {
    subscribe,
    unsubscribe,
    MessageContext
} from 'lightning/messageService';

export default class NksNavTaskWorkAllocation extends LightningElement {
    @api personId;
    @api taskType;
    @api themeGroup;
    @api theme;
    @api subTheme;
    @api selectedNavUnit;
    @track result;
    isSearching;
    errorMessage;
    selectedId = '';

    @api
    get selectedUnitName() {
        return this.selectedNavUnit ? this.selectedNavUnit.navn : '';
    }

    @api
    get selectedUnitId() {
        return this.selectedNavUnit ? this.selectedNavUnit.sfId : '';
    }

    @api
    get selectedUnitNumber() {
        return this.selectedNavUnit ? this.selectedNavUnit.enhetNr : '';
    }

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    get showContent() {
        return (null != this.personId && null != this.themeGroup && null != this.theme && null != this.taskType);
    }

    //Lightning message service subscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                nksSingleValueUpdate,
                (message) => this.handleMessage(message)
            );
        }
    }

    //Lightning message service unsubsubscribe
    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    // Handler for message received by component
    handleMessage(message) {
        let fieldName = message.name;
        let value = message.value;

        switch (fieldName) {
            case 'themeGroupCode':
                this.themeGroup = value;
                break;
            case 'themeCode':
                this.theme = value;
                break;
            case 'subThemeCode':
                this.subTheme = value;
                break;
            case 'NKS_Task_Type__c':
                this.taskType = value;
                break;
        }

        let showContent = this.showContent
        if (true == showContent) {
            this.findAllocation();
        }
    }

    //Send query to NORG2
    async findAllocation() {
        this.isSearching = true;
        const input = {
            personId: this.personId,
            themeGroup: this.themeGroup,
            theme: this.theme,
            subTheme: this.subTheme
        }

        try {
            const data = await getWorkAllocations(input);
            this.result = data;
            this.errorMessage = data.errorMessage;

            if (true === data.success && 1 <= data.units.length) {
                this.selectedNavUnit = data.units[0];
                this.selectedId = data.units[0].sfId;
            }
            this.isSearching = false;
        } catch (error) {
            this.errorMessage = error.body.message;
            this.isSearching = false;
        }
    }
}