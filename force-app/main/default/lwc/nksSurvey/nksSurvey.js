import { LightningElement, api, track } from 'lwc';
import PNG_EMOJIS from '@salesforce/resourceUrl/nksSurveyEmojis';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class NksSurvey extends LightningElement {
    show = true;
    backgroundColor = '#dec8ef';
    title = 'Tilfredhetsmåling';
    question = 'Hva synes du om den nye meldekort-funksjonen?';

    @track emojis = [
        {
            id: 'emoji1',
            title: 'veldig dårlig',
            url: `${PNG_EMOJIS}/emoji1.png`,
            selected: false
        },
        {
            id: 'emoji2',
            title: 'dårlig',
            url: `${PNG_EMOJIS}/emoji2.png`,
            selected: false
        },
        {
            id: 'emoji3',
            title: 'nøytral',
            url: `${PNG_EMOJIS}/emoji3.png`,
            selected: false
        },
        {
            id: 'emoji4',
            title: 'bra',
            url: `${PNG_EMOJIS}/emoji4.png`,
            selected: false
        },
        {
            id: 'emoji5',
            title: 'veldig bra',
            url: `${PNG_EMOJIS}/emoji5.png`,
            selected: false
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

    handleClick(event) {
        const id = event.currentTarget.getAttribute('data-id');
        this.emojis.forEach((emoji) => {
            let element = this.template.querySelector(`img[data-id="${emoji.id}"]`);
            let item = this.template.querySelector(`li[data-id="${emoji.id}"]`);
            if (emoji.id === id) {
                element.setAttribute('src', `${PNG_EMOJIS}/${emoji.id}hover.png`);
                emoji.selected = true;
                item.className = 'slds-box slds-box_small emojiSelected';
            } else {
                element.setAttribute('src', `${PNG_EMOJIS}/${emoji.id}.png`);
                emoji.selected = false;
                item.className = 'slds-box slds-box_small emoji';
            }
        });
    }

    handleMouseOver(event) {
        const id = event.currentTarget.getAttribute('data-id');
        let element = this.template.querySelector(`img[data-id="${id}"]`);
        element.setAttribute('src', `${PNG_EMOJIS}/${id}hover.png`);
    }

    handleMouseOut(event) {
        const id = event.currentTarget.getAttribute('data-id');
        this.emojis.forEach((emoji) => {
            let element = this.template.querySelector(`img[data-id="${emoji.id}"]`);
            if (emoji.id === id && !emoji.selected) {
                element.setAttribute('src', `${PNG_EMOJIS}/${id}.png`);
            }
        });
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
