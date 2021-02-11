import { LightningElement, api } from 'lwc';
import {
    FlowNavigationBackEvent,
    FlowNavigationNextEvent,
    FlowNavigationFinishEvent
} from 'lightning/flowSupport';

export default class NksFlowNavigation extends LightningElement {
    @api action;
    @api buttonLabel;
    @api buttonAlignment;

    handleButtonClick(event) {
        let flowEvent;

        switch (this.action) {
            case 'NEXT':
                flowEvent = new FlowNavigationNextEvent();
                break;
            case 'BACK':
                flowEvent = new FlowNavigationBackEvent();
                break;
            case 'FINISH':
                flowEvent = new FlowNavigationFinishEvent();
                break;
            default:
                break;
        }

        if (flowEvent) this.dispatchEvent(flowEvent);
    }

    get alignment() {
        switch (this.buttonAlignment) {
            case 'RIGHT':
                return 'end';
            case 'LEFT':
                return '';
            case 'CENTER':
                return 'center';
            default:
                return 'end';
        }
    }
}
