import { LightningElement, api } from 'lwc';

export default class NksPersonHenvendelseMessage extends LightningElement {
    @api message;

    showJournalpostInfo = false;

    setShowJournalpostInfo() {
        this.showJournalpostInfo = !this.showJournalpostInfo;
    }

    get getDate() {
        return this.formateDate(this.message.opprettetDatoFormatted);
    }

    get lestDato() {
        return this.formateDate(this.message.opprettetDatoFormatted);
    }

    get alignment() {
        return this.message.erMeldingFraBruker ? '' : 'slds-grid_align-end';
    }

    formateDate(d) {
        return d
            ? new Date(d).toLocaleDateString('no-NO', {
                  year: 'numeric',
                  month: '2-digit',
                  day: '2-digit',
                  hour: '2-digit',
                  minute: '2-digit'
              })
            : null;
    }
}
