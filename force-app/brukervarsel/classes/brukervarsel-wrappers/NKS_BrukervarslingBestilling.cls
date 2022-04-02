public with sharing class NKS_BrukervarslingBestilling {
    @AuraEnabled
    public String aktoerId;
    @AuraEnabled
    public Datetime bestilt;
    @AuraEnabled
    public String personIdent;
    @AuraEnabled
    public Integer reVarselingsintervall;
    @AuraEnabled
    public DateTime sisteVarselutsendelse;
    @AuraEnabled
    public List<NKS_Brukervarsel> varselListe;
    @AuraEnabled
    public String varseltypeId;
    @AuraEnabled
    public UN_TmsEventApiEvent brukernotifikasjon;
}