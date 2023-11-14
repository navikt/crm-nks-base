import { LightningElement, track, wire } from 'lwc';
import SVG_EMOJIS from '@salesforce/resourceUrl/nksSurveyEmojis';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSurvey from '@salesforce/apex/NKS_InternalSurveyController.getSurvey';
import hasAnswered from '@salesforce/apex/NKS_InternalSurveyController.hasAnswered';
import createAnsweredRecord from '@salesforce/apex/NKS_InternalSurveyController.createAnsweredRecord';
import CreateResponseRecord from '@salesforce/apex/NKS_InternalSurveyController.CreateResponseRecord';

export default class NksSurvey extends LightningElement {
    surveyId;
    backgroundColor;
    title;
    question;
    isAnswered;
    isRendered = false;
    recordTypeId;

    @track emojis = [
        {
            id: 'emoji1',
            title: 'veldig dårlig',
            url: `${SVG_EMOJIS}/emoji1.svg`,
            selected: false,
            value: 1
        },
        {
            id: 'emoji2',
            title: 'dårlig',
            url: `${SVG_EMOJIS}/emoji2.svg`,
            selected: false,
            value: 2
        },
        {
            id: 'emoji3',
            title: 'nøytral',
            url: `${SVG_EMOJIS}/emoji3.svg`,
            selected: false,
            value: 3
        },
        {
            id: 'emoji4',
            title: 'bra',
            url: `${SVG_EMOJIS}/emoji4.svg`,
            selected: false,
            value: 4
        },
        {
            id: 'emoji5',
            title: 'veldig bra',
            url: `${SVG_EMOJIS}/emoji5.svg`,
            selected: false,
            value: 5
        }
    ];
    @track rating;
    @track comment;
    @track show = true;

    @wire(getSurvey)
    wiredSurvey({ data, error }) {
        if (data) {
            this.surveyId = data.Id;
            this.backgroundColor = data.Background_Color__c;
            this.title = data.NKS_Title__c;
            this.question = data.NKS_Question__c;
        } else if (error) {
            console.log('Problem getting survey: ' + error);
        }
    }

    get style() {
        return `background-color: ${this.backgroundColor}`;
    }

    get hide() {
        return !this.show || this.isAnswered;
    }

    renderedCallback() {
        if (this.surveyId) {
            hasAnswered({ surveyId: this.surveyId }).then((res) => {
                this.isAnswered = res;
                console.log('Survey is answered: ', res);
            });
        }
    }

    handleClick(event) {
        const id = event.currentTarget.getAttribute('data-id');
        this.emojis.forEach((emoji) => {
            let element = this.template.querySelector(`img[data-id="${emoji.id}"]`);
            if (emoji.id === id) {
                element.setAttribute('src', `${SVG_EMOJIS}/${emoji.id}select.svg`);
                emoji.selected = true;
                this.rating = event.currentTarget.getAttribute('value');
            } else {
                element.setAttribute('src', `${SVG_EMOJIS}/${emoji.id}.svg`);
                emoji.selected = false;
            }
        });
    }

    handleMouseOver(event) {
        const id = event.currentTarget.getAttribute('data-id');
        let element = this.template.querySelector(`img[data-id="${id}"]`);
        element.setAttribute('src', `${SVG_EMOJIS}/${id}hover.svg`);
    }

    handleMouseOut(event) {
        const id = event.currentTarget.getAttribute('data-id');
        this.emojis.forEach((emoji) => {
            let element = this.template.querySelector(`img[data-id="${emoji.id}"]`);
            if (emoji.id === id && !emoji.selected) {
                element.setAttribute('src', `${SVG_EMOJIS}/${id}.svg`);
            }
        });
    }

    handleChange() {
        this.comment = this.template.querySelector('lightning-textarea').value;
    }

    handleSend() {
        this.show = false;
        const event = new ShowToastEvent({
            title: 'Tilbakemeldingen din er mottatt.',
            message: 'Ha en fin dag videre!',
            variant: 'success'
        });
        this.dispatchEvent(event);
        createAnsweredRecord({ surveyId: this.surveyId }).then((res) => {
            console.log('Result of Survey Answered creation: ', res);
            console.log('rating from lwc: ', this.rating);
            console.log('comment from lwc: ', this.comment);
            CreateResponseRecord({ rating: this.rating, comment: this.comment }).then((result) => {
                console.log('Result of Survey Response creation: ', result);
            });
        });
    }

    handleCancel() {
        this.show = false;
        createAnsweredRecord({ surveyId: this.surveyId }).then((res) => {
            console.log('Result of Survey Answered creation: ', res);
        });
    }
}
