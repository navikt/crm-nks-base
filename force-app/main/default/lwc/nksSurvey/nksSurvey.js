import { LightningElement, wire } from 'lwc';
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
    startDate;
    endDate;
    rating;
    comment;
    show = true;

    @wire(getSurvey)
    wiredSurvey({ data, error }) {
        if (data) {
            this.surveyId = data.Id;
            this.backgroundColor = data.NKS_Background_Color__c;
            this.title = data.NKS_Title__c;
            this.question = data.NKS_Question__c;
            this.startDate = data.NKS_Start_Date__c;
            this.endDate = data.NKS_End_Date__c;
        } else if (error) {
            console.log('Problem getting survey: ' + error);
        }
    }

    get background() {
        return `background-color: ${this.backgroundColor}`;
    }

    get hide() {
        return !this.show || this.isAnswered;
    }

    get isValid() {
        let valid = false;
        if (this.surveyId) {
            if (this.startDate && this.endDate) {
                valid = new Date(this.endDate) - new Date(this.startDate) > 0 ? true : false;
            } else {
                valid = true;
            }
        }
        return valid;
    }

    renderedCallback() {
        if (this.surveyId && !this.isRendered) {
            hasAnswered({ surveyId: this.surveyId }).then((res) => {
                this.isAnswered = res;
                this.isRendered = true;
                console.log('Survey is answered: ', res);
            });
        }
    }

    handleClick(event) {
        this.rating = event.currentTarget.getAttribute('value');
        const currentId = event.currentTarget.getAttribute('data-id');
        this.handleSelected(currentId);
    }

    handleSelected(currentId) {
        const emojiIds = ['emoji1', 'emoji2', 'emoji3', 'emoji4', 'emoji5'];

        for (const emojiId of emojiIds) {
            const paths = this.template.querySelectorAll(`li[data-id="${emojiId}"] path`);

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
