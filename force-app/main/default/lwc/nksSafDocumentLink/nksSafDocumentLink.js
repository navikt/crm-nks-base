import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NksSafDocumentLink extends NavigationMixin(LightningElement) {
    @api dokumentInfo;
    @api journalpostId;
    isSladdet;
    isReadable;
    hasAccessToArkiv;
    fileName;
    title;

    connectedCallback() {
        this.setDocumentVariantValues();
        this.setTitle();
    }

    get hasLogicalAttachments() {
        let isTrue = (this.dokumentInfo.logiskeVedlegg) ? true : false;
        return isTrue;
    }

    setDocumentVariantValues() {
        this.isSladded = false;
        this.isReadable = false;
        this.hasAccessToArkiv = false;
        this.fileName = '';

        if (this.dokumentInfo.dokumentVarianter) {
            this.dokumentInfo.dokumentVarianter.forEach(dokumentVariant => {
                if (dokumentVariant.saksbehandlerHarTilgang) {
                    if (dokumentVariant.variantformat === "ARKIV") {
                        this.hasAccessToArkiv = true;
                        this.fileName = dokumentVariant.filnavn;
                        this.isReadable = dokumentVariant.saksbehandlerHarTilgang
                    }

                    if (dokumentVariant.variantformat === "SLADDET") {
                        this.isSladded = true;
                        this.fileName = dokumentVariant.filnavn;

                        if (false === this.hasAccessToArkiv) {
                            this.isReadable = dokumentVariant.saksbehandlerHarTilgang
                        }
                    }

                }
            });
        }
    }

    setTitle() {
        let title = this.dokumentInfo.tittel;

        if (true === this.isSladdet && false === this.hasAccessToArkiv) {
            title += " (Sladdet)";
        }

        this.title = title;
    }

    navigateToDocument() {
        let url = this.buildURL(this.journalpostId, this.dokumentInfo.dokumentInfoId, this.fileName);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        }).then(generatedUrl => {
            window.open(generatedUrl);
        });
    }

    buildURL(journalpostId, dokumentInfoId, fileName) {
        return '/apex/NKS_SafViewDocument?journalId=' + journalpostId + '&documentInfoId=' + dokumentInfoId + '&variantFormat=ARKIV&fileName=' + fileName + '&width=100%&height=900px';
    }

}