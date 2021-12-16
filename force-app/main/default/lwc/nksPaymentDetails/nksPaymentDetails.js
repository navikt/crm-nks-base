import { LightningElement, api } from 'lwc';
import getBeregning from '@salesforce/apex/NKS_PaymentListController.getBeregningsGrunnlag';

const arenaYtelser = ['Dagpenger', 'AAP'];
export default class NksPaymentDetails extends LightningElement {
    @api ytelse;
    @api displayHeader;
    @api labels;
    @api personIdent;
    arenaDetails;

    renderedCallback() {
        console.log('YTELSE: ' + this.ytelse.ytelsestype.value);
        if (arenaYtelser.includes(this.ytelse.ytelsestype.value) && !this.arenaDetails) {
            this.getArenaDetails();
        }
    }

    getArenaDetails() {
        getBeregning({
            personIdent: this.personIdent
        })
            .then((data) => {
                console.log(data);
            })
            .catch((error) => {
                console.log(error);
            });
    }
}
