import { LightningElement, wire, track, api } from 'lwc';
import nksSingleValueUpdate from '@salesforce/messageChannel/nksSingleValueUpdate__c';
import getTaskTypes from '@salesforce/apex/NKS_NAVTaskTypeController.getTaskTypes';
import { publish, subscribe, unsubscribe, MessageContext } from 'lightning/messageService';

export default class NksTaskTypePicklist extends LightningElement {
    @api showcomponent;
    @api theme;
    @track theme = this.theme;
    @track tasktypes = [];
    tasktype;
    commoncodes;

    @wire(MessageContext)
    messageContext;

    @api
    get selectedTaskType() {
        let selectedTaskType = '';
        if (this.commoncodes) {
            for (let tt of this.commoncodes) {
                if (tt.id === this.tasktype) {
                    selectedTaskType = tt.commoncode;
                    break;
                }
            }
        }
        return selectedTaskType;
    }

    @api
    get selectedTaskTypeId() {
        return this.tasktype;
    }

    handleTaskTypeChange(event) {
        this.tasktype = event.detail.value;
        this.publishFieldChange('tasktype', this.tasktype);
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
        this.findTaskTypes();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(this.messageContext, nksSingleValueUpdate, (message) =>
                this.handleMessage(message)
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(message) {
        let fieldName = message.name;
        let value = message.value;

        switch (fieldName) {
            case 'themeCode':
                this.theme = value;
                this.findTaskTypes();
                break;
            case 'createtask':
                this.showcomponent = value;
                break;
        }
    }

    async findTaskTypes() {
        const input = {
            themeCode: this.theme
        };
        this.tasktypes = [];
        try {
            getTaskTypes(input).then((result) => {
                this.commoncodes = result;
                result.forEach((tasktype) => {
                    const option = {
                        value: tasktype.id,
                        label: tasktype.name
                    };
                    this.tasktypes = [...this.tasktypes, option];
                });
            });
        } catch (error) {
            this.errorMessage = error.body.message;
        }
    }

    publishFieldChange(field, value) {
        const payload = { name: field, value: value };
        publish(this.messageContext, nksSingleValueUpdate, payload);
    }
}
