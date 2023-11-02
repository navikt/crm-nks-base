import { LightningElement, api, track } from 'lwc';
import SVG_EMOJIS from '@salesforce/resourceUrl/nksSurveyEmojis';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class NksSurvey extends LightningElement {
    show = true;
    backgroundColor = '#dec8ef';
    title = '';
    question = 'Hva synes du om den nye meldekort-funksjonen?';

    @track emojis = [
        {
            id: 'emoji1',
            title: 'veldig dårlig',
            url: `${SVG_EMOJIS}/emoji1.svg#emoji1`
        },
        {
            id: 'emoji2',
            title: 'dårlig',
            url: `${SVG_EMOJIS}/emoji2.svg#emoji2`
        },
        {
            id: 'emoji3',
            title: 'nøytral',
            url: `${SVG_EMOJIS}/emoji3.svg#emoji3`
        },
        {
            id: 'emoji4',
            title: 'bra',
            url: `${SVG_EMOJIS}/emoji4.svg#emoji4`
        },
        {
            id: 'emoji5',
            title: 'veldig bra',
            url: `${SVG_EMOJIS}/emoji5.svg#emoji5`
        }
    ];
    @track outputText;

    get style() {
        return `background-color: ${this.backgroundColor}`;
    }

    /**
     * Note: All functions are for test
     */
    handleCloseClick() {
        this.show = false;
    }

    handleEmojiClick(event) {
        console.log(event.currentTarget.getAttribute('data-id'));
    }

    handleChange() {
        this.outputText = this.template.querySelector('lightning-textarea').value;
    }

    handleSend() {
        console.log('feedback: ', this.outputText);
        const event = new ShowToastEvent({
            title: 'Tilbakemeldingen din er mottatt.',
            message: 'Ha en fin dag videre!',
            variant: 'success'
        });
        this.dispatchEvent(event);
        this.show = false;
    }

    handleCancel() {
        this.show = false;
    }
}
