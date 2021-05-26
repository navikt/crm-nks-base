public with sharing class BrukervarslingBestilling {
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
    public List<Brukervarsel> varselListe;
    @AuraEnabled
    public String varseltypeId;
}
