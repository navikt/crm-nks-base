import { LightningElement, wire, track, api } from 'lwc';
import nksSingleValueUpdate from '@salesforce/messageChannel/nksSingleValueUpdate__c';
import getTaskTypes from '@salesforce/apex/NKS_NAVTaskTypeController.getTaskTypes';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';

export default class NksTaskTypePicklist extends LightningElement {
    @track tasktypes = [];
    tasktype;
    commoncodes;
    @api showcomponent;
    @api theme;
    theme;
    @track theme = this.theme;

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
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
        console.log('CALLBACK: ');
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
                //this.findTaskTypes();
                break;
        }

        let showcomponent = this.showcomponent;
        if (true == showcomponent) {
            console.log('showcontent true');
            this.findTaskTypes();
        }
    }

    async findTaskTypes() {
        const input = {
            themeCode: this.theme
        };
        this.tasktypes = [];
        console.log('FINDING TASKTYPES with theme code: ' + this.theme);
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

    get showcomponent() {
        return this.showcomponent;
    }
}
