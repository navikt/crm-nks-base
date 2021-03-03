import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import ThirdPartyAccountLinkKey from '@salesforce/schema/ThirdPartyAccountLink.ThirdPartyAccountLinkKey';

export default class NksSafDocumentLink extends NavigationMixin(LightningElement) {
    @api dokumentInfo;
    @api journalpostId;

    dokumentvariant;

    connectedCallback() {
        this.setDocumentVariant();
    }

    get isLoaded() {
        return this.dokumentvariant ? true : false;
    }

    get title() {
        let title = this.dokumentInfo.tittel;
        let meta = [];

        if (this.isSladdet) {
            meta.push('Sladdet');
        }

        if (this.isSkjermet) {
            meta.push('Skjermet');
        }

        let metaText = meta.length > 0 ? ' (' + meta.join(', ') + ')' : '';

        return title + metaText;
    }

    get isReadable() {
        return this.dokumentvariant.saksbehandlerHarTilgang === true;
    }

    get isSladdet() {
        return this.dokumentvariant && this.dokumentvariant.variantformat === 'SLADDET';
    }

    get isSkjermet() {
        return this.dokumentvariant && this.dokumentvariant.skjerming === 'POL';
    }

    get isMarkedForDeletion() {
        return this.dokumentvariant && this.dokumentvariant.skjerming === 'FEIL';
    }

    get fileName() {
        return this.dokumentvariant ? this.dokumentvariant.filnavn : '';
    }

    get variantFormat() {
        return this.dokumentvariant.variantformat;
    }

    get isOriginalJournalpost() {
        return this.journalpostId === this.dokumentInfo.originalJournalpostId;
    }

    get hasLogicalAttachments() {
        let isTrue = this.dokumentInfo.logiskeVedlegg ? true : false;
        return isTrue;
    }

    setDocumentVariant() {
        this.dokumentvariant = null;

        if (this.dokumentInfo.dokumentVarianter) {
            this.dokumentInfo.dokumentVarianter.forEach((dokumentVariant) => {
                if (dokumentVariant.variantformat === 'ARKIV') {
                    this.dokumentvariant = dokumentVariant;
                    if (dokumentVariant.saksbehandlerHarTilgang) {
                        return;
                    }
                }

                if (dokumentVariant.variantformat === 'FULLVERSJON') {
                    this.dokumentvariant = dokumentVariant;
                }
                if (this.dokumentvariant == null && dokumentVariant.variantformat === 'SLADDET') {
                    this.dokumentvariant = dokumentVariant;
                }
            });
        }
    }

    navigateToDocument() {
        let url = this.buildURL(
            this.journalpostId,
            this.dokumentInfo.dokumentInfoId,
            this.variantFormat,
            this.fileName
        );
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        }).then((generatedUrl) => {
            window.open(generatedUrl);
        });
    }

    buildURL(journalpostId, dokumentInfoId, variantFormat, fileName) {
        return (
            '/apex/NKS_SafViewDocument?journalId=' +
            journalpostId +
            '&documentInfoId=' +
            dokumentInfoId +
            '&variantFormat=' +
            variantFormat +
            '&fileName=' +
            fileName +
            '&width=100%&height=900px'
        );
    }
}
