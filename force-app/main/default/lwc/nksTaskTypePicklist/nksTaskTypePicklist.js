import { LightningElement, wire, track, api } from 'lwc';
import nksSingleValueUpdate from '@salesforce/messageChannel/nksSingleValueUpdate__c';
import getTaskTypes from '@salesforce/apex/NKS_NAVTaskTypeController.getTaskTypes';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';

export default class NksTaskTypePicklist extends LightningElement {
    @track tasktypes = [];
    @track tasktype;
    @api tasktype;
    @api theme;
    theme;
    @track theme = this.theme;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscribeToMessageChannel();
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
        console.log('handle message');

        switch (fieldName) {
            case 'themeCode':
                this.theme = value;
                break;
        }

        let showContent = this.showContent;
        if (true == showContent) {
            console.log('showcontent true');
            this.findTaskTypes();
        }
    }

    async findTaskTypes() {
        const input = {
            themeCode: this.theme
        };
        this.tasktypes = [];
        try {
            getTaskTypes(input).then((result) => {
                console.log('map1: ' + JSON.stringify(result));
                var map = result;
                for (var key in map) {
                    const option = {
                        value: key,
                        label: map[key]
                    };
                    this.tasktypes = [...this.tasktypes, option];
                }
            });
        } catch (error) {
            this.errorMessage = error.body.message;
        }
    }

    get showContent() {
        return null != this.theme;
    }
}
