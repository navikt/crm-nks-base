import { LightningElement, track, wire, api } from 'lwc';
import getSecurityQuestion from '@salesforce/apex/CRM_SecurityQuestionPicker.getSecurityQuestion';
import ACCOUNT_FIELD from '@salesforce/schema/Case.AccountId';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

export default class CrmSecurityQuestion extends LightningElement {
    @track question;
    @track answer;
    @track questionsAsked = [];
    @track disabled = true;
    @track closed = false;
    @track personId;
    @api recordId;
    useErrorColor = false;

    @wire(getSecurityQuestion, { accountId: '$personId', usedQuestions: [] })
    fetchData({ error, data }) {
        if (error) {
            console.log(error);
            this.question = 'Det oppsto en feil, vennligst prøv på nytt.';
            this.answer = error.body.message;
            this.useErrorColor = true;
        } else if (data) {
            this.question = data.question;
            this.answer = data.answer;
            this.questionsAsked = data.usedQuestions;
            this.useErrorColor = this.questionsAsked == null;
        }
        this.disabled = false;
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [ACCOUNT_FIELD]
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            this.personId = getFieldValue(data, ACCOUNT_FIELD);
        }

        if (error) {
            this.addError(error);
        }
    }

    async handleNextQuestion() {
        this.disabled = true;
        getSecurityQuestion({
            accountId: this.personId,
            usedQuestions: this.questionsAsked
        })
            .then((data) => {
                this.question = data.question;
                this.answer = data.answer;
                this.questionsAsked = data.usedQuestions;
                this.disabled = false;
                this.useErrorColor = this.questionsAsked == null;
            })
            .catch((error) => {
                console.log(error);
                this.question = 'Det oppsto en feil, vennligst prøv på nytt.';
                this.answer = error.body.message;
                this.disabled = false;
                this.useErrorColor = true;
            });
    }

    handleClose() {
        this.closed = true;
    }

    get questionClass() {
        return 'bold slds-m-left_xx-small' + (this.useErrorColor ? ' errorColor' : '');
    }
}
