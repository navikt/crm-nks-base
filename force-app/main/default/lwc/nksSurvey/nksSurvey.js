import { LightningElement, api, track } from 'lwc';
import PNG_EMOJIS from '@salesforce/resourceUrl/nksSurveyEmojis';
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
            url: `${PNG_EMOJIS}/emoji1.png`
        },
        {
            id: 'emoji2',
            title: 'dårlig',
            url: `${PNG_EMOJIS}/emoji2.png`
        },
        {
            id: 'emoji3',
            title: 'nøytral',
            url: `${PNG_EMOJIS}/emoji3.png`
        },
        {
            id: 'emoji4',
            title: 'bra',
            url: `${PNG_EMOJIS}/emoji4.png`
        },
        {
            id: 'emoji5',
            title: 'veldig bra',
            url: `${PNG_EMOJIS}/emoji5.png`
        }
    ];
    @track outputText;

    get style() {
        return `background-color: ${this.backgroundColor}`;
    }

    /**
     * Note: some functions are for test
     */
    handleCloseClick() {
        this.show = false;
    }

    handleEmojiClick(event) {
        console.log(event.currentTarget.getAttribute('title'));
    }

    handleMouseOver(event) {
        const id = event.currentTarget.getAttribute('data-id');
        let element = this.template.querySelector(`img[data-id="${id}"]`);
        element.setAttribute('src', `${PNG_EMOJIS}/${id}hover.png`);
    }

    handleMouseOut(event) {
        const id = event.currentTarget.getAttribute('data-id');
        let element = this.template.querySelector(`img[data-id="${id}"]`);
        element.setAttribute('src', `${PNG_EMOJIS}/${id}.png`);
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
