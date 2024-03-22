import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSurvey from '@salesforce/apex/NKS_InternalSurveyController.getSurvey';
import createSurveyResponse from '@salesforce/apex/NKS_InternalSurveyController.createSurveyResponse';
export default class NksSurvey extends LightningElement {
    surveyId;
    backgroundColor;
    title;
    question;
    startDate;
    endDate;
    rating;
    comment;
    isAnswered = false;

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
        createSurveyResponse({
            surveyId: this.surveyId,
            rating: this.rating,
            comment: this.comment,
            isCanceled: false
        })
            .then(() => {
                const event = new ShowToastEvent({
                    title: 'Tilbakemeldingen din er mottatt.',
                    message: 'Ha en fin dag videre!',
                    variant: 'success'
                });
                this.dispatchEvent(event);
            })
            .catch((error) => {
                const event = new ShowToastEvent({
                    title: 'Feilmelding',
                    message: 'Det har oppstått en feil ved sending av tilbakemeling.',
                    variant: 'error'
                });
                this.dispatchEvent(event);

                console.log('Det har oppstått en feil ved sending av undersøkelsen: ', error);
            });
    }

    handleCancel() {
        this.isAnswered = true;
        createSurveyResponse({ surveyId: this.surveyId, rating: 0, comment: '', isCanceled: true });
    }
}
