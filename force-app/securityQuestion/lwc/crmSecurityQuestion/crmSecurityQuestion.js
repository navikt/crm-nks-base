import { LightningElement, wire, api } from 'lwc';
import getSecurityQuestionTPS from '@salesforce/apex/CRM_SecurityQuestionPicker.getQuestionsTPS';
import getSecurityQuestionKRR from '@salesforce/apex/CRM_SecurityQuestionPicker.getQuestionsKRR';
import getSecurityQuestionPDL from '@salesforce/apex/CRM_SecurityQuestionPicker.getQuestionsPDL';
import ACCOUNT_FIELD from '@salesforce/schema/Case.AccountId';
import PERSON_ID from '@salesforce/schema/Case.Account.CRM_Person__c';
import PERSON_NAME from '@salesforce/schema/Person__c.Name';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

export default class CrmSecurityQuestion extends LightningElement {
    @api recordId;
    personId = null;
    personIdent = null;
    question = '';
    answer = '';
    questionsAsked = [];
    unusedQuestions = [];
    useErrorColor = false;
    disabled = true;
    closed = false;
    isLoading = false;

    get isNextButtonDisabled() {
        return this.isLoading || this.disabled || (this.unusedQuestions.length < 1 && this.questionsAsked.length < 1);
    }

    getNextQuestion() {
        this.disabled = true;
        if (this.unusedQuestions.length > 0) {
            const newQuestion = this.unusedQuestions.splice((this.unusedQuestions.length * Math.random()) | 0, 1)[0];
            this.questionsAsked.push(newQuestion);
            this.question = newQuestion.question;
            this.answer = newQuestion.answer;
        } else {
            this.unusedQuestions.push(...this.questionsAsked);
            this.questionsAsked = [];
            this.question = 'Ingen flere spørsmål';
            this.answer = 'Trykk på "Nytt"-knappen for å se tidligere spørsmål';
        }
        this.disabled = false;
    }

    loadQuestions() {
        this.unusedQuestions = [];
        this.questionsAsked = [];
        this.isLoading = true;
        Promise.allSettled([
            getSecurityQuestionTPS({ ident: this.personIdent }),
            getSecurityQuestionKRR({ ident: this.personIdent }),
            getSecurityQuestionPDL({ ident: this.personIdent })
        ]).then((values) => {
            values.forEach((value) => {
                if (value.status === 'fulfilled' && Array.isArray(value.value)) {
                    this.unusedQuestions.push(...value.value);
                } else if (value.status === 'rejected') {
                    console.error(value.reason);
                }
            });
            this.getNextQuestion();
            this.isLoading = false;
            console.log(this.unusedQuestions);
        });
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [ACCOUNT_FIELD, PERSON_ID]
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            this.personId = getFieldValue(data, PERSON_ID);
            this.questionsAsked = null;
        }

        if (error) {
            console.error(error);
        }
    }

    @wire(getRecord, { recordId: '$personId', fields: [PERSON_NAME] }) wirePerson({ error, data }) {
        if (data) {
            this.personIdent = getFieldValue(data, PERSON_NAME);
            this.loadQuestions();
        }
        if (error) {
            console.error(error);
        }
    }

    handleClose() {
        this.closed = true;
    }

    get questionClass() {
        return 'question bold slds-var-m-left_xx-small' + (this.useErrorColor ? ' errorColor' : '');
    }
}
