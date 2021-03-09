public with sharing class NKS_SafDokumentvariant {
    @AuraEnabled public String variantformat; //-> Enum VariantFormat
    @AuraEnabled public String filnavn;
    @AuraEnabled public Boolean saksbehandlerHarTilgang;
    @AuraEnabled public String skjerming; //-> Enum SkjermingsType
}