import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getNavUnit from '@salesforce/apex/NKS_NavUnitSingleController.findUnit';
import getContactInformation from '@salesforce/apex/NKS_NavUnitSingleController.getContactInformation';

export default class NksNavUnitSingle extends LightningElement {
    @api recordId; // The record id
    @api objectApiName; // The object api name
    @api relationField; // Points to either the Person__c.Id or a field containging a unit number
    @api type; // If based on person location or unit
    @api allSectionsOpenOnLoad = false; // If all sections should be open when the component loads
    @api numCols = 2; // Number of columns for the displayed fields
    @api cardLayout = false; // If true, use the card layout, if not use box layout
    @api boxLayout = false;

    @track navUnit; // The nav unit
    @track contactInformation; // The nav unit contact information

    unitNumber;

    wireFields;
    errorMessage; // Error messages
    isError = false; // If error has occured
    isLoaded = false; // If the nav unit and contact information has loaded
    firstRun = false;
    noLayout = false;

    connectedCallback() {
        this.setAttribute('title', 'NAV Enhet');
        this.wireFields = [this.objectApiName + '.Id'];

        if (!this.cardLayout && !this.boxLayout) {
            this.noLayout = true;
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
            if (this.wiredNavUnit && this.wiredNavUnit.data) {
                this.isLoaded = false;
                refreshApex(this.wiredNavUnit).then(() => {
                    this.setWiredNavUnit();
                });
            }
        }

        if (error) {
            this.errorMessage = error;
            this.isError = true;
            this.isLoaded = true;
        }
    }

    @wire(getNavUnit, {
        field: '$relationField',
        parentObject: '$objectApiName',
        parentRecordId: '$recordId',
        type: '$type'
    })
    wiredGetNavUnit(value) {
        this.wiredNavUnit = value;
        this.setWiredNavUnit();
    }

    setWiredNavUnit() {
        const { data, error } = this.wiredNavUnit;
        if (data) {
            let newUnitNumber = data.unit && data.unit.enhetNr ? data.unit.enhetNr : null;

            this.isLoaded = this.unitNumber === newUnitNumber ? true : false;

            this.isError = !data.success;
            this.navUnit = data.unit;
            this.unitNumber = newUnitNumber;
            this.errorMessage += data.errorMessage ? ' ' + data.errorMessage : '';
        }

        if (error) {
            this.errorMessage = error;
            this.isError = true;
            this.isLoaded = true;
        }
    }

    @wire(getContactInformation, { unitNumber: '$unitNumber' }) wiredGetContactInformation(value) {
        this.wiredContactInformation = value;
        this.setWiredContactInformation();
    }

    setWiredContactInformation() {
        const { data, error } = this.wiredContactInformation;
        if (data) {
            this.isError = !data.success;
            this.contactInformation = data.contactInformation;
            this.errorMessage += data.errorMessage ? ' ' + data.errorMessage : '';
            this.isLoaded = true;
        }

        if (error) {
            this.errorMessage = error;
            this.isError = true;
            this.isLoaded = true;
        }
    }

    /**
     * Find the nav unit and the contact information
     */
    // async findNavUnit() {
    //     this.isLoaded = false;
    //     let errorString = '';

    //     try {
    //         const unitData = await getNavUnit({
    //             field: this.relationField,
    //             parentObject: this.objectApiName,
    //             parentRecordId: this.recordId,
    //             type: this.type
    //         });
    //         this.isError = !unitData.success;
    //         this.navUnit = unitData.unit;
    //         errorString += unitData.errorMessage ? ' ' + unitData.errorMessage : '';

    //         if (false === this.isError) {
    //             try {
    //                 const contactInfoData = await getContactInformation({
    //                     unitNumber: this.navUnit.enhetNr
    //                 });
    //                 this.isError = !contactInfoData.success;
    //                 this.contactInformation = contactInfoData.contactInformation;
    //                 errorString += contactInfoData.errorMessage ? ' ' + contactInfoData.errorMessage : '';
    //             } catch (error) {
    //                 errorString += error.body.message;
    //                 this.isError = true;
    //             }
    //         }
    //     } catch (error) {
    //         errorString += error.body.message;
    //         this.isError = true;
    //     }

    //     this.errorMessage = errorString;
    //     this.isLoaded = true;
    // }
}
