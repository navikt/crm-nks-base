import { LightningElement, track, wire } from 'lwc';
//import SVG_EMOJIS from '@salesforce/resourceUrl/nksSurveyEmojis';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSurvey from '@salesforce/apex/NKS_InternalSurveyController.getSurvey';
import hasAnswered from '@salesforce/apex/NKS_InternalSurveyController.hasAnswered';
import createAnsweredRecord from '@salesforce/apex/NKS_InternalSurveyController.createAnsweredRecord';
import createResponseRecord from '@salesforce/apex/NKS_InternalSurveyController.createResponseRecord';
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
            selected: false,
            value: 1
        },
        {
            id: 'emoji2',
            title: 'dårlig',
            selected: false,
            value: 2
        },
        {
            id: 'emoji3',
            title: 'nøytral',
            selected: false,
            value: 3
        },
        {
            id: 'emoji4',
            title: 'bra',
            selected: false,
            value: 4
        },
        {
            id: 'emoji5',
            title: 'veldig bra',
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
        /*
        let svgs = this.template.querySelectorAll('c-nks-svg-render');

        svgs.forEach(function (svg) {
            svg.addEventListener('mouseover', function () {
                this.fill1 = '#F6C912';
                this.fill2 = '#F9D952';
            });
        });

        svgs.forEach(function (svg) {
            svg.addEventListener('mouseout', function (event) {
                const id = event.currentTarget.getAttribute('selected');
                //console.log('selected: ', id);
                this.fill1 = '#F9DA57';
                this.fill2 = '#FBE981';
            });
        });

        svgs.forEach(function (svg) {
            svg.addEventListener('click', function () {
                this.fill1 = '#EEB11E';
                this.fill2 = '#F9CD18';
            });
        });*/

        if (this.surveyId && !this.isRendered) {
            hasAnswered({ surveyId: this.surveyId }).then((res) => {
                this.isAnswered = res;
                this.isRendered = true;
                console.log('Survey is answered: ', res);
            });
        }
    }

    handleClick(event) {
        const id = event.currentTarget.getAttribute('data-id');

        this.emojis.forEach((emoji) => {
            if (emoji.id === id) {
                emoji.selected = true;
                this.rating = event.currentTarget.getAttribute('value');
            } else {
                emoji.selected = false;
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

            createResponseRecord({ surveyId: this.surveyId, rating: this.rating, comment: this.comment }).then(
                (result) => {
                    console.log('Result of Survey Response creation: ', result);
                }
            );
        });
    }

    handleCancel() {
        this.show = false;
        createAnsweredRecord({ surveyId: this.surveyId }).then((res) => {
            console.log('Result of Survey Answered creation: ', res);
        });
    }
}
