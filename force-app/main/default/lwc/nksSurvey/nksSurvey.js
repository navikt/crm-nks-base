import { LightningElement, track, wire } from 'lwc';
import PNG_EMOJIS from '@salesforce/resourceUrl/nksSurveyEmojis';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSurvey from '@salesforce/apex/NKS_InternalSurveyController.getSurvey';
import hasAnswered from '@salesforce/apex/NKS_InternalSurveyController.hasAnswered';
import { createRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import SURVEY_RESPONSE_OBJECT from '@salesforce/schema/NKS_Survey_Response__c';
import SURVEY_FIELD from '@salesforce/schema/NKS_Survey_Response__c.NKS_Survey__c';
import RATING_FIELD from '@salesforce/schema/NKS_Survey_Response__c.NKS_Rating__c';
import COMMENT_FIELD from '@salesforce/schema/NKS_Survey_Response__c.NKS_Comment__c';
import RECORD_TYPE_ID_FIELD from '@salesforce/schema/NKS_Survey_Response__c.RecordTypeId';
import USER_FIELD from '@salesforce/schema/NKS_Survey_Response__c.User__c';
import ANSWERED_FIELD from '@salesforce/schema/NKS_Survey_Response__c.NKS_Answered__c';
import USER_ID from '@salesforce/user/Id';

export default class NksSurvey extends LightningElement {
    surveyId;
    backgroundColor;
    title;
    question;
    userId = USER_ID;
    isAnswered;

    @track emojis = [
        {
            id: 'emoji1',
            title: 'veldig dårlig',
            url: `${PNG_EMOJIS}/emoji1.png`,
            selected: false,
            value: 1
        },
        {
            id: 'emoji2',
            title: 'dårlig',
            url: `${PNG_EMOJIS}/emoji2.png`,
            selected: false,
            value: 2
        },
        {
            id: 'emoji3',
            title: 'nøytral',
            url: `${PNG_EMOJIS}/emoji3.png`,
            selected: false,
            value: 3
        },
        {
            id: 'emoji4',
            title: 'bra',
            url: `${PNG_EMOJIS}/emoji4.png`,
            selected: false,
            value: 4
        },
        {
            id: 'emoji5',
            title: 'veldig bra',
            url: `${PNG_EMOJIS}/emoji5.png`,
            selected: false,
            value: 5
        }
    ];
    @track rating;
    @track comment;
    @track show = true;

    @wire(getObjectInfo, { objectApiName: SURVEY_RESPONSE_OBJECT })
    objectInfo;

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

    /**
     * Note: some functions are for test
     */
    renderedCallback() {
        if (this.surveyId) {
            hasAnswered({ surveyId: this.surveyId }).then((res) => {
                this.isAnswered = res;
                console.log('Survey is answered: ', res);
            });
        }
    }

    getRecordTypeId(recordTypeName) {
        const rtis = this.objectInfo.data.recordTypeInfos;
        return Object.keys(rtis).find((rti) => rtis[rti].name === recordTypeName);
    }

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
                this.rating = event.currentTarget.getAttribute('value');
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
        this.comment = this.template.querySelector('lightning-textarea').value;
    }

    handleSend() {
        this.createAnsweredRecord();
        this.createResponseRecord();
        this.show = false;
        const event = new ShowToastEvent({
            title: 'Tilbakemeldingen din er mottatt.',
            message: 'Ha en fin dag videre!',
            variant: 'success'
        });
        this.dispatchEvent(event);
    }

    handleCancel() {
        this.createAnsweredRecord();
        this.show = false;
    }

    createAnsweredRecord() {
        const answeredFields = {};

        answeredFields[SURVEY_FIELD.fieldApiName] = this.surveyId;
        answeredFields[RECORD_TYPE_ID_FIELD.fieldApiName] = this.getRecordTypeId('Survey Answered');
        answeredFields[USER_FIELD.fieldApiName] = this.userId;
        answeredFields[ANSWERED_FIELD.fieldApiName] = true;

        const recordInput = {
            apiName: SURVEY_RESPONSE_OBJECT.objectApiName,
            fields: answeredFields
        };

        createRecord(recordInput).then((record) => {
            console.log('SurveyAnswered is created: ', record);
        });
    }

    createResponseRecord() {
        const responseFields = {};

        responseFields[SURVEY_FIELD.fieldApiName] = this.surveyId;
        responseFields[RECORD_TYPE_ID_FIELD.fieldApiName] = this.getRecordTypeId('Survey Response');
        responseFields[RATING_FIELD.fieldApiName] = this.rating;
        responseFields[COMMENT_FIELD.fieldApiName] = this.comment;

        const recordInput = {
            apiName: SURVEY_RESPONSE_OBJECT.objectApiName,
            fields: responseFields
        };

        createRecord(recordInput).then((record) => {
            console.log('SurveyResponse is created: ', record);
        });
    }
}
