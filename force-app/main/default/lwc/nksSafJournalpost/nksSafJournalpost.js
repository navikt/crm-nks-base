import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NksSafJournalpost extends LightningElement {
    @api journalpost;

    get fromToType() {
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

        return fromToType;
    }

    get jornalpostDate() {
        const options = { year: 'numeric', month: '2-digit', day: '2-digit' };
        let dateString = this.journalpost.datoOpprettet;

        return new Date(dateString).toLocaleDateString('no-NO', options);
    }

    get mainDocument() {
        if (this.journalpost.dokumenter && 0 < this.journalpost.dokumenter.length) {
            return this.journalpost.dokumenter[0];
        }

        return null;
    }

    get attachments() {
        if (this.journalpost.dokumenter) {
            return this.journalpost.dokumenter.filter((dokument, i) => {
                if (i > 0) { return dokument }
            });
        }

        return [];
    }

    get nmbOfAttachments() {
        return this.getNumberOfAttachments();
    }

    get hasAttachments() {
        return 0 < this.getNumberOfAttachments() ? true : false;
    }

    getNumberOfAttachments() {
        let numberOfAttachments = 0;
        if (this.journalpost.dokumenter) {
            numberOfAttachments = this.journalpost.dokumenter.length - 1;
        }

        return numberOfAttachments;
    }
}