import { LightningElement, api } from 'lwc';
import getBeregning from '@salesforce/apex/NKS_PaymentListController.getBeregningsGrunnlag';

const arenaYtelser = ['Dagpenger', 'AAP'];
export default class NksPaymentDetails extends LightningElement {
    @api ytelse;
    @api displayHeader;
    @api labels;
    @api personIdent;
    arenaDetails;

    get ytelseFromDate() {
        return this.ytelse.ytelsesperiode?.fom;
    }

    get ytelseToDate() {
        return this.ytelse.ytelsesperiode?.tom;
    }

    get ytelseType() {
        return this.ytelse.ytelsestype?.value;
    }

    get anmerkninger() {
        return this.arenaDetails?.anmerkninger; //List of anmerkning wrappers
    }

    renderedCallback() {
        console.log('YTELSE: ' + this.ytelseType);
        if (arenaYtelser.includes(this.ytelseType) && !this.arenaDetails) {
            this.getArenaDetails();
        }
    }

    getArenaDetails() {
        getBeregning({
            personIdent: this.personIdent
        })
            .then((data) => {
                console.log(data);
                let details = JSON.parse(data);
                this.arenaDetails = details[2];
            })
            .catch((error) => {
                console.log(error);
            });
    }
}
