public with sharing class NKS_SafDokumentInfo {
    @AuraEnabled
    public String dokumentInfoId;
    @AuraEnabled
    public String tittel;
    @AuraEnabled
    public String brevkode;
    @AuraEnabled
    public String dokumentstatus; //-> Enum
    @AuraEnabled
    public DateTime datoFerdigstilt;
    @AuraEnabled
    public String orginalJournalpostId;
    @AuraEnabled
    public String skjerming; //-> Enum
    @AuraEnabled
    public List<NKS_SafLogiskVedlegg> logiskeVedlegg;
    @AuraEnabled
    public List<NKS_SafDokumentvariant> dokumentVarianter;
}
