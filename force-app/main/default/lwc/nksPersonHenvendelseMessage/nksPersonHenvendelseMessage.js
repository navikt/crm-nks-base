import { LightningElement, api } from 'lwc';
import navLogoIcon from '@salesforce/resourceUrl/NKS_nav_logo_rod';

export default class NksPersonHenvendelseMessage extends LightningElement {
    @api message;

    showJournalpostInfo = false;

    setShowJournalpostInfo() {
        this.showJournalpostInfo = !this.showJournalpostInfo;
    }

    get getDate() {
        return this.formateDate(this.message.opprettetDato);
    }

    get lestDato() {
        return this.formateDate(this.message.lestDato);
    }

    get navLogo() {
        return navLogoIcon + '#rodLogo';
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
