import { LightningElement, api } from 'lwc';

export default class NksBrukervarselMelding extends LightningElement {
    @api message;

    get sendtDate() {
        return this.message.sendt
            ? new Date(this.message.sendt).toLocaleDateString('no-NO', {
                  year: 'numeric',
                  month: '2-digit',
                  day: '2-digit'
              })
            : null;
    }

    get showReceiverInfo() {
        if (this.message.mottakerInformasjon) {
            switch (this.message.kanal) {
                case 'EPOST':
                    return true;
                case 'SMS':
                    return true;
                default:
                    return false;
            }
        }
        return false;
    }

    get showMessageTitle() {
        return this.message.varseltittel ? true : false;
    }

    get showLink() {
        return this.message.varselURL && this.message.varselURL.lenth > 0 ? true : false;
    }

    get receiverInfo() {
        let receiverInfo = this.message.mottakerInformasjon ? this.message.mottakerInformasjon : '';
        switch (this.message.kanal) {
            case 'EPOST':
                return 'Epost: ' + receiverInfo;
            case 'SMS':
                return 'Tlf: ' + receiverInfo;
            default:
                return null;
        }
    }
}
