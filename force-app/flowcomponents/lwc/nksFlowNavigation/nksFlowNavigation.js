import { LightningElement, api } from 'lwc';
import { FlowNavigationBackEvent, FlowNavigationNextEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { publishToAmplitude } from 'c/amplitude';
export default class NksFlowNavigation extends LightningElement {
    @api action = 'NEXT';
    @api buttonLabel;
    @api buttonAlignment;
    @api stretched = false;
    @api availableActions = ['NEXT', 'BACK', 'FINISH'];
    @api buttonVariant = 'brand';
    @api removeFooter = false;

    handleButtonClick() {
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
                console.error('Invalid action:', this.action);
                return;
        }

        if (flowEvent) {
            this.dispatchEvent(flowEvent);
        }
        publishToAmplitude('Clicked ', { type: this.action });
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

    get validAction() {
        return this.availableActions.find((action) => action === this.action);
    }

    get buttonStyle() {
        return this.stretched ? 'display: grid; width: 100%;' : '';
    }
}
