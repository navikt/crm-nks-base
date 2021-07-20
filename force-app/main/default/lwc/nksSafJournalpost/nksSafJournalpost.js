import { LightningElement, api, track } from 'lwc';

export default class NksSafJournalpost extends LightningElement {
    _journalpost;

    @track mainDocument = null;
    @track attachments = null;

    numberOfAttachments = 0;
    fromToType = null;
    journalpostDate = null;

    @api set journalpost(value) {
        this._journalpost = value;

        this.getNumberOfAttachments();
        this.setFromToType();
        this.setMainDocument();
        this.setAttachments();
    }

    get hasAttachments() {
        return 0 < this.numberOfAttachments ? true : false;
    }

    get journalpost() {
        return this._journalpost;
    }

    setFromToType() {
        let fromToType;
        let kanal = this.journalpost.kanal && this.journalpost.kanal != 'UKJENT' ? this.journalpost.kanalnavn : null;
        switch (this.journalpost.journalposttype) {
            case 'I':
                fromToType = 'Fra ' + this.journalpost.avsenderMottaker.navn;
                break;
            case 'U':
                fromToType = 'Fra NAV (Sendt til ' + this.journalpost.avsenderMottaker.navn + ')';
                break;
            case 'N':
                fromToType = 'Notat';
                break;
            default:
                fromToType = '';
                break;
        }

        fromToType = kanal ? fromToType + ' - ' + kanal : fromToType;

        this.fromToType = fromToType;
    }

    setJournalpostDate() {
        const options = { year: 'numeric', month: '2-digit', day: '2-digit' };

        let dateString = '';

        switch (this.journalpost.journalposttype) {
            case 'I':
                dateString = this.firstNotNull(['DATO_REGISTRERT']);
                break;
            case 'U':
                dateString = this.firstNotNull(['DATO_EKSPEDERT', 'DATO_SENDT_PRINT', 'DATO_JOURNALFOERT']);
                break;
            case 'N':
                dateString = this.firstNotNull(['DATO_JOURNALFOERT']);
                break;
        }

        return new Date(dateString).toLocaleDateString('no-NO', options);
    }

    firstNotNull(datoTypes) {
        datoTypes.forEach((datoType) => {
            let date = this.journalpost.relevanteDatoer.find((relevantDato) => {
                return relevantDato.datoType === datoType ? relevantDato.dato : null;
            });

            if (date) {
                return date;
            }
        });

        return '';
    }

    setMainDocument() {
        this.mainDocument = null;

        if (this.journalpost.dokumenter && 0 < this.journalpost.dokumenter.length) {
            this.mainDocument = this.journalpost.dokumenter[0];
        }
    }

    setAttachments() {
        let attachments = [];
        if (this.journalpost.dokumenter) {
            attachments = this.journalpost.dokumenter.filter((dokument, i) => {
                if (i > 0) {
                    return dokument;
                }
            });
        }

        this.attachments = attachments;
    }

    getNumberOfAttachments() {
        let numberOfAttachments = 0;

        if (this.journalpost.dokumenter && this.journalpost.dokumenter.length > 1) {
            numberOfAttachments = this.journalpost.dokumenter.length - 1;
        }

        this.numberOfAttachments = numberOfAttachments;
    }
}
