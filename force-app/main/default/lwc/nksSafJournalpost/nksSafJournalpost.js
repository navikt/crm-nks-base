import { LightningElement, api, track } from 'lwc';

export default class NksSafJournalpost extends LightningElement {
    @api journalpost;

    @track mainDocument = null;
    @track attachments = null;

    numberOfAttachments = 0;
    hasAttachments = false;
    jornalpostDate = null;
    fromToType = null;

    connectedCallback() {
        this.getNumberOfAttachments();
        this.setFromToType();
        this.setMainDocument();
        this.setAttachments();
        this.setJornalpostDate();
        this.hasAttachments = (0 < this.numberOfAttachments) ? true : false;
    }

    setFromToType() {
        let fromToType;
        switch (this.journalpost.journalposttype) {
            case "I":
                fromToType = 'Fra ' + this.journalpost.avsenderMottaker.navn;
                break;
            case "U":
                fromToType = 'Fra NAV (Sendt til ' + this.journalpost.avsenderMottaker.navn + ')';
                break;
            case "N":
                fromToType = 'Notat';
                break;
            default:
                fromToType = '';
                break;
        }

        this.fromToType = fromToType;
    }

    setJornalpostDate() {
        const options = { year: 'numeric', month: '2-digit', day: '2-digit' };
        let dateString = this.journalpost.datoOpprettet;

        this.jornalpostDate = new Date(dateString).toLocaleDateString('no-NO', options);
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
                if (i > 0) { return dokument }
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