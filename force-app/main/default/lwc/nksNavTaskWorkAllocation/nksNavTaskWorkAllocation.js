import { LightningElement, api, track, wire } from 'lwc';
import nksSingleValueUpdate from '@salesforce/messageChannel/nksSingleValueUpdate__c';
import getWorkAllocations from '@salesforce/apex/NKSNavTaskWorkAllocationController.getWorkAllocations';
import getUserNavUnit from '@salesforce/apex/NKSNavTaskWorkAllocationController.getUserNavUnitId';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/NavUnit__c.Id';
import NAME_FIELD from '@salesforce/schema/NavUnit__c.Name';
import UNIT_NUMBER_FIELD from '@salesforce/schema/NavUnit__c.INT_UnitNumber__c';
import USER_ID from '@salesforce/user/Id';
import USER_NAV_UNIT_FIELD from '@salesforce/schema/User.Department';
import USER_NAV_IDENT_FIELD from '@salesforce/schema/User.CRM_NAV_Ident__c';

import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';

//#### LABEL IMPORTS ####
import VALIDATION_ERROR from '@salesforce/label/c.NKS_Nav_Task_Work_Allocation_Validation_Error';
import DELEGATE_TO_SELF_LABEL from '@salesforce/label/c.NKS_Nav_Task_Work_Allocation_Delegate_to_Self';

export default class NksNavTaskWorkAllocation extends LightningElement {
    labels = {
        VALIDATION_ERROR,
        DELEGATE_TO_SELF_LABEL
    };

    @api personId;
    @api taskType;
    @api themeGroup;
    @api theme;
    @api subTheme;
    @track result;
    isSearching;
    errorMessage;
    selectedId;
    runningUserUnitNumber;
    runningUserIdent;
    delegateToSelf = false;

    @api
    get selectedUnitName() {
        let value = getFieldValue(this.navUnit.data, NAME_FIELD);
        return value ? value : '';
    }

    @api
    get selectedUnitId() {
        let value = getFieldValue(this.navUnit.data, ID_FIELD);
        return value ? value : '';
    }

    set selectedUnitId(unitId) {
        this.selectedId = unitId;
    }

    @api
    get selectedUnitNumber() {
        let value = getFieldValue(this.navUnit.data, UNIT_NUMBER_FIELD);
        return value ? value : '';
    }

    @api
    get assignedResource() {
        return this.delegateToSelf === true ? this.runningUserIdent : null;
    }

    get navUnitInputDisabled() {
        return this.isSearching || this.delegateToSelf === true;
    }

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, {
        recordId: '$selectedId',
        fields: [ID_FIELD, NAME_FIELD, UNIT_NUMBER_FIELD]
    })
    navUnit;

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [USER_NAV_UNIT_FIELD, USER_NAV_IDENT_FIELD]
    })
    wireUser({ error, data }) {
        if (data) {
            this.runningUserIdent = data.fields.CRM_NAV_Ident__c.value;
            this.runningUserUnitNumber = data.fields.Department.value;
        }
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    get showContent() {
        return null != this.personId && null != this.theme && null != this.taskType;
    }

    //Lightning message service subscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(this.messageContext, nksSingleValueUpdate, (message) =>
                this.handleMessage(message)
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

        let showContent = this.showContent;
        if (true == showContent) {
            this.findAllocation();
        }
    }

    //Send query to NORG2
    async findAllocation() {
        this.isSearching = true;
        const input = {
            personId: this.personId,
            themeGroupCode: this.themeGroup,
            themeCode: this.theme,
            themeSubThemeCode: this.subTheme,
            taskType: this.taskType
        };

        try {
            const data = await getWorkAllocations(input);
            this.result = data;
            this.errorMessage = data.errorMessage;

            if (true === data.success && 1 <= data.units.length) {
                this.selectedId = data.units[0].sfId;
            }
            this.isSearching = false;
        } catch (error) {
            this.errorMessage = error.body.message;
            this.isSearching = false;
        }
    }

    @wire(getUserNavUnit, { userUnitNumber: '$runningUserUnitNumber' })
    userNavUnitId;

    onChange(event) {
        let ids = event.detail.value;
        this.selectedId = ids && 1 === ids.length ? ids[0] : null;
    }

    delegationChange(event) {
        this.delegateToSelf = event.target.checked;

        this.selectedId = this.delegateToSelf === true ? this.userNavUnitId.data : null;
    }

    @api
    validate() {
        //Theme and theme group must be set
        if (false == this.showContent || (this.selectedId && this.navUnit)) {
            return { isValid: true };
        } else {
            return {
                isValid: false,
                errorMessage: VALIDATION_ERROR
            };
        }
    }
}
