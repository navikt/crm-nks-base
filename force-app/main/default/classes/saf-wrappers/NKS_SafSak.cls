public with sharing class NKS_SafSak {
    @AuraEnabled
    public DateTime datoOpprettet;
    @AuraEnabled
    public String fagsakId;
    @AuraEnabled
    public String fagsaksystem;
    @AuraEnabled
    public String sakstype; // Enum -> FAGSAK, GENERELL_SAK
}
