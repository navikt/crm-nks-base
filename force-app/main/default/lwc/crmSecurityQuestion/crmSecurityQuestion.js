import { LightningElement, track, wire, api } from 'lwc';
import getSecurityQuestion from '@salesforce/apex/CRM_SecurityQuestionPicker.getSecurityQuestion';
import ACCOUNT_FIELD from '@salesforce/schema/Case.AccountId';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

export default class CrmSecurityQuestion extends LightningElement {
    question;
    @track answer;
    questionsAsked = null;
    @track disabled = true;
    closed = false;
    personId;
    @api recordId;
    useErrorColor = false;

    fetchData({ error, data }) {
        if (error && error != null) {
            this.question = 'Det oppsto en feil, vennligst prøv på nytt.';
            this.answer = '';
            this.useErrorColor = true;
        } else if (data && data != null) {
            if (
                this.questionsAsked == data.usedQuestions &&
                this.questionsAsked == null &&
                data.question != 'Fant ikke brukeren'
            ) {
                this.question = 'Brukeren har ingen gyldige spørsmål.';
                this.answer = '';
                this.useErrorColor = true;
            } else {
                this.question = data.question;
                this.answer = data.answer;
                this.questionsAsked = data.usedQuestions;
                this.useErrorColor = false;
            }
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
            this.questionsAsked = null;
            this.handleNextQuestion();
        }

        if (error) {
            this.addError(error);
        }
    }

    async handleNextQuestion() {
        this.disabled = true;
        this.answer = 'Henter spørsmål...';
        this.useErrorColor = false;
        this.question = '';
        getSecurityQuestion({
            accountId: this.personId,
            usedQuestions: this.questionsAsked
        })
            .then((data) => {
                this.fetchData({ error: null, data: data });
            })
            .catch((error) => {
                this.fetchData({ error: error, data: null });
            });
    }

    handleClose() {
        this.closed = true;
    }

    get questionClass() {
        return 'question bold slds-m-left_xx-small' + (this.useErrorColor ? ' errorColor' : '');
    }
}
