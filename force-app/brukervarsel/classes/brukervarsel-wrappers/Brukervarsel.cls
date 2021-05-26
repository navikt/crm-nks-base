public with sharing class Brukervarsel {
    @AuraEnabled
    public Datetime distribuert;
    @AuraEnabled
    public String kanal;
    @AuraEnabled
    public String kontaktinfo;
    @AuraEnabled
    public Boolean reVarsel;
    @AuraEnabled
    public Datetime sendt;
    @AuraEnabled
    public String varselURL;
    @AuraEnabled
    public String varseltekst;
    @AuraEnabled
    public String varseltittel;
}
