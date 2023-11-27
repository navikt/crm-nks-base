import { LightningElement, wire, track } from 'lwc';
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
    startDate;
    endDate;
    rating;
    comment;

    @track isAnswered = false;

    @wire(getSurvey)
    wiredSurvey({ data, error }) {
        if (data) {
            this.surveyId = data.Id;
            this.backgroundColor = data.NKS_Background_Color__c;
            this.title = data.NKS_Title__c;
            this.question = data.NKS_Question__c;
        } else if (error) {
            console.log('Problem getting survey: ' + error);
        }
    }

    @wire(hasAnswered, { surveyId: '$surveyId' })
    wiredAnswered({ error, data }) {
        if (data) {
            this.isAnswered = data;
            console.log('is answered: ', this.isAnswered);
        } else if (error) {
            console.log(error);
        }
    }

    get background() {
        return `background-color: ${this.backgroundColor}`;
    }

    handleClick(event) {
        this.rating = event.currentTarget.getAttribute('value');
        const currentId = 'emoji' + this.rating;
        this.handleSelected(currentId);
    }

    handleSelected(currentId) {
        const emojiIds = ['emoji1', 'emoji2', 'emoji3', 'emoji4', 'emoji5'];

        for (const emojiId of emojiIds) {
            const paths = this.template.querySelectorAll(`div[data-id="${emojiId}"] path`);

            if (currentId === emojiId) {
                paths[0].setAttribute('class', 'select1');
                paths[1].setAttribute('class', 'select2');
            } else {
                paths[0].setAttribute('class', 'path1');
                paths[1].setAttribute('class', 'path2');
            }
        }
    }

    handleChange() {
        this.comment = this.template.querySelector('lightning-textarea').value;
    }

    handleSend() {
        this.isAnswered = true;
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
        this.isAnswered = true;
        createAnsweredRecord({ surveyId: this.surveyId }).then((res) => {
            console.log('Result of Survey Answered creation: ', res);
        });
    }
}
