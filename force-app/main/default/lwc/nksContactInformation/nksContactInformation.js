import { LightningElement, api, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { resolve } from 'c/nksComponentsUtils';
import { refreshApex } from '@salesforce/apex';
import LoggerUtility from 'c/loggerUtility';
import EMAIL_FIELD from '@salesforce/schema/Person__c.NKS_Email__c';
import PHONE_FIELD from '@salesforce/schema/Person__c.NKS_Mobile_Phone__c';
import PHONE_1_FIELD from '@salesforce/schema/Person__c.NKS_Phone_1__c';
import PHONE_2_FIELD from '@salesforce/schema/Person__c.NKS_Phone_2__c';
import BANK_ACCOUNT_FIELD from '@salesforce/schema/Person__c.INT_BankAccountNumber__c';
import BANK_ACCOUNT_UDATED_FIELD from '@salesforce/schema/Person__c.INT_BankAccountNumberLastModified__c';
import BANK_ACCOUNT_SOURCE_FIELD from '@salesforce/schema/Person__c.INT_BankAccountSource__c';
import KRR_RESERVATION_FIELD from '@salesforce/schema/Person__c.INT_KRR_Reservation__c';
import KRR_VERIFIED_FIELD from '@salesforce/schema/Person__c.INT_VerifiedFromKRR__c';
import PDL_LAST_UPDATED_FIELD from '@salesforce/schema/Person__c.INT_LastUpdatedFromPDL__c';
import KRR_LAST_UPDATED_FIELD from '@salesforce/schema/Person__c.INT_LastUpdatedFromKRR__c';
import COUNTY_FIELD from '@salesforce/schema/Person__c.NKS_County__c';

import getRelatedRecord from '@salesforce/apex/NksRecordInfoController.getRelatedRecord';

const LABELS = {
    mobile: 'Mobilnummer',
    phoneFromNav: 'Telefon fra nav.no'
};

const PERSON_CONTACT_FIELDS = [
    EMAIL_FIELD,
    PHONE_FIELD,
    PHONE_1_FIELD,
    PHONE_2_FIELD,
    BANK_ACCOUNT_FIELD,
    BANK_ACCOUNT_UDATED_FIELD,
    KRR_RESERVATION_FIELD,
    KRR_VERIFIED_FIELD,
    KRR_LAST_UPDATED_FIELD,
    PDL_LAST_UPDATED_FIELD,
    BANK_ACCOUNT_SOURCE_FIELD,
    COUNTY_FIELD
];

export default class NksContactInformation extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;

    email;
    phone;
    phone1;
    phone2;
    bankAccount;
    bankAccountLastUpdated;
    bankAccountSource;
    krrReservation;
    krrVerified;
    krrLastUpdated;
    pdlLastUpdated;
    personId;
    county;
    wiredPersonInfoResult;
    errorMessage;
    isError = false;
    isLoading = true;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
            if (this.relationshipField && this.objectApiName) {
                this.getRelatedRecordId(this.relationshipField, this.objectApiName);
            }
        }
        if (error) {
            this.handleError(error);
            console.error(error);
            this.isLoading = false;
        }
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: PERSON_CONTACT_FIELDS
    })
    wiredPersonInfo(result) {
        this.wiredPersonInfoResult = result;
        if (result?.data) {
            this.populatePersonFields(result.data);
            this.isLoading = false;
        } else if (result?.error) {
            this.handleError(result.error);
            console.error(result.error);
            this.isLoading = false;
        }
    }

    populatePersonFields(data) {
        this.email = getFieldValue(data, EMAIL_FIELD);
        this.phone = getFieldValue(data, PHONE_FIELD);
        this.phone1 = getFieldValue(data, PHONE_1_FIELD);
        this.phone2 = getFieldValue(data, PHONE_2_FIELD);
        this.bankAccount = getFieldValue(data, BANK_ACCOUNT_FIELD);
        this.bankAccountLastUpdated = getFieldValue(data, BANK_ACCOUNT_UDATED_FIELD);
        this.krrReservation = getFieldValue(data, KRR_RESERVATION_FIELD);
        this.krrVerified = getFieldValue(data, KRR_VERIFIED_FIELD);
        this.krrLastUpdated = getFieldValue(data, KRR_LAST_UPDATED_FIELD);
        this.pdlLastUpdated = getFieldValue(data, PDL_LAST_UPDATED_FIELD);
        this.bankAccountSource = getFieldValue(data, BANK_ACCOUNT_SOURCE_FIELD);
        this.county = getFieldValue(data, COUNTY_FIELD);
    }

    getRelatedRecordId(relationshipField, objectApiName) {
        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: relationshipField,
            objectApiName: objectApiName
        })
            .then((record) => {
                if (!record) {
                    LoggerUtility.logError(
                        'NKS',
                        'ContactInformation',
                        null,
                        'No related record found for relationshipField: ' + relationshipField,
                        ' and objectApiName: ' + objectApiName,
                        this.recordId
                    );
                }
                this.personId = resolve(relationshipField, record);
                refreshApex(this.wiredPersonInfoResult); // In case wiredPersonInfo is cached to empty values before getRelatedRecord is finished
            })
            .catch((error) => {
                LoggerUtility.logError('NKS', 'ContactInformation', error, 'Error on getRelatedRecord', this.recordId);
                this.handleError(error);
                console.error(error);
                this.isLoading = false;
            });
    }

    handleError(error) {
        this.errorMessage = 'Unknown error';
        if (Array.isArray(error.body)) {
            this.errorMessage = error.body.map((e) => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            this.errorMessage = error.body.message;
        }
        this.isError = true;
    }

    getFormattedPhone(phone, label) {
        return phone ? `${label}: ${phone}` : '';
    }

    get formattedPhone() {
        return this.getFormattedPhone(this.phone, LABELS.mobile);
    }

    get formattedPhone1() {
        return this.getFormattedPhone(this.phone1, LABELS.phoneFromNav);
    }

    get formattedPhone2() {
        return this.getFormattedPhone(this.phone2, LABELS.phoneFromNav);
    }

    get fancyError() {
        return JSON.stringify(this.errorMessage);
    }

    get krrReservationTranslation() {
        return this.krrReservation ? 'Ja' : 'Nei';
    }

    get krrLastUpdatedFormatted() {
        return this.formatSystemDate(this.krrLastUpdated, 'KRR');
    }

    get pdlLastUpdatedFormatted() {
        return this.formatSystemDate(this.pdlLastUpdated, 'PDL - Folkeregisteret');
    }

    get bankAccountLastUpdatedFormatted() {
        return this.formatSystemDate(this.bankAccountLastUpdated, 'KRP');
    }

    get wireFields() {
        return this.objectApiName ? [`${this.objectApiName}.Id`] : [];
    }

    formatSystemDate(updatedDate, sourceSystem) {
        if (!updatedDate) {
            return '';
        }
        const date = new Date(updatedDate);
        const formatter = new Intl.DateTimeFormat('nb-NO', {
            day: 'numeric',
            month: 'long',
            year: 'numeric'
        });
        const formattedSourceSystem =
            sourceSystem === 'KRP' ? (this.bankAccountSource ? this.bankAccountSource : '') : sourceSystem;

        return `Oppdatert ${formatter.format(date)} av ${formattedSourceSystem}`;
    }
}
