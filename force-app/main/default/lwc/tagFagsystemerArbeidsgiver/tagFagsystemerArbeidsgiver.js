import { LightningElement, api, track, wire } from 'lwc';
import getAccount from '@salesforce/apex/TAG_FagsystemerArbeidsgiverController.getAccount';
import checkFagsoneIpRange from '@salesforce/apex/TAG_FagsystemerArbeidsgiverController.checkFagsoneIpRange';
//https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.apex_result_caching

// https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.reference_salesforce_modules

const filterFunc = (listToFilterOut, listToFilterIn) => (element) => {
    return (
        (!listToFilterOut || !listToFilterOut.includes(element.name)) &&
        (!listToFilterIn || listToFilterIn.includes(element.name))
    );
};

export default class TagFagsystemerArbeidsgiver extends LightningElement {
    @api recordId;
    @api title;
    @api accountId;
    @track showLinks;
    @track inFagsone = false;
    @api filterList;

    possibleLinks = [
        { name: 'AAregister', field: 'AAregisterURL__c' },
        { name: 'Gosys', field: 'GosysURL__c' },
        { name: 'Rekrutteringsbistand', field: 'RekrutteringsbistandURL__c' },
        { name: 'Tiltaksgjennomforing', field: 'TiltaksgjennomforingURL__c' },
        { name: 'TiltakRefusjon', field: 'TiltakRefusjonURL__c' }
    ];
    
    connectedCallback() {
        checkFagsoneIpRange().then((res) => {
            this.inFagsone = res.isInFagsone;
            if (this.inFagsone === false) {
                console.log('Ip is: ' + res.ip);
            }
        });
    }

    renderedCallback() {
        const listOfFilter =
            typeof this.filterList === 'string' ? this.filterList.replaceAll(' ', '').split(',') : this.filterList;
        this.fields = this.possibleLinks
            .map((link, index) => ({
                ...link,
                id: index,
                custom: link.field == null,
                show: !('show' in link) || (link.show ?? false)
            }))
            .filter(filterFunc(listOfFilter));
    }

    get size() {
        return 6;
    }

    @wire(getAccount, {
        recordId: '$recordId'
    })
    wireorgNr(res) {
        this._refresh = res;
        if (res.error) {
            console.log(res.error);
        }
        if (res.data) {
            this.accountId = res.data;
        }
    }

   get showContent() {
        return this.accountId != null;
    }

    get showRefreshButton() {
        return !(!this.recordId);
    }

    handleLoaded() {
        this.showLinks = true;
    }
}
