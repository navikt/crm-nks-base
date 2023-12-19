import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSurvey from '@salesforce/apex/NKS_InternalSurveyController.getSurvey';
import hasAnswered from '@salesforce/apex/NKS_InternalSurveyController.hasAnswered';
import createAnsweredRecord from '@salesforce/apex/NKS_InternalSurveyController.mortenNiceThing';
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
        } else if (error) {
            console.log('Problem checking if survey is answered: ', error);
        }
    }

    get background() {
        return `background-color: ${this.backgroundColor}`;
    }

    handleClick(event) {
        this.rating = event.currentTarget.getAttribute('value');
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
        createAnsweredRecord({
            surveyId: this.surveyId,
            rating: this.rating,
            comment: this.comment,
            isCanceled: false
        }).then(() => {
            console.log('Response creation was successful!');
        });
    }

    handleCancel() {
        this.isAnswered = true;
        createAnsweredRecord({ surveyId: this.surveyId, rating: 0, comment: '', isCanceled: true }).then(() => {
            console.log('Response creation was successful!');
        });
    }
}
