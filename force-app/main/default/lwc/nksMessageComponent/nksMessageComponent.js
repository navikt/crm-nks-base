import { LightningElement, api } from 'lwc';

export default class NksMessageComponent extends LightningElement {
    @api recordId;
    @api singleThread;

    startTransferFlow() {
        this.dispatchToolbarAction('NKS_STO_transfer');
    }

    dispatchToolbarAction(flowName) {
        //Sending event to parent to initialize flow
        const toolbarActionEvent = new CustomEvent('toolbaraction', {
            detail: { flowName }
        });

        this.dispatchEvent(toolbarActionEvent);
    }
}
