import { LightningElement, wire } from 'lwc';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { getFocusedTabInfo, refreshTab } from 'lightning/platformWorkspaceApi';
import { publish, MessageContext } from 'lightning/messageService';
import TAB_REFRESH from '@salesforce/messageChannel/tabRefresh__c';

export default class NksTabRefresher extends LightningElement {
    @wire(MessageContext) messageContext;

    connectedCallback() {
        getFocusedTabInfo()
            .then((tabInfo) => {
                return refreshTab(tabInfo.tabId, { includeAllSubtabs: true });
            })
            .catch((error) => {
                console.error('Error refreshing tab: ', error);
            })
            .finally(() => {
                // LMS needed to refreshApex on related custom LWC components
                publish(this.messageContext, TAB_REFRESH);
                // Immediately move Flow to next screen so user doesn’t notice this step
                this.dispatchEvent(new FlowNavigationFinishEvent());
            });
    }
}
