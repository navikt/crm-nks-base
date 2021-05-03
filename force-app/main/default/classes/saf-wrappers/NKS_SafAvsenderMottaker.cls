public with sharing class NKS_SafAvsenderMottaker {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String type; //-> ENUM
    @AuraEnabled
    public String navn;
    @AuraEnabled
    public String land;
    @AuraEnabled
    public String erLikBruker;
}
