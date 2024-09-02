import { LightningElement, api } from 'lwc';
import { FlowNavigationBackEvent, FlowNavigationNextEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';
import templateWithFooter from './templateWithFooter.html';
import templateWithoutFooter from './templateWithoutFooter.html';
import { publishToAmplitude } from 'c/amplitude';
export default class NksFlowNavigation extends LightningElement {
    @api action = 'NEXT';
    @api buttonLabel;
    @api buttonAlignment;
    @api stretched = false;
    @api availableActions = ['NEXT', 'BACK', 'FINISH'];
    @api buttonVariant = 'brand';
    @api removeFooter = false;

    render() {
        return this.removeFooter ? templateWithoutFooter : templateWithFooter;
    }

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
        publishToAmplitude('Clicked on flow navigation button', { type: this.action });
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

    get buttonClass() {
        return `slds-button slds-button_stretch slds-grid slds-grid_align-center responsive-button ${
            this.buttonVariant === 'brand' ? 'slds-button_brand' : 'slds-button_outline-brand'
        }`;
    }
}
