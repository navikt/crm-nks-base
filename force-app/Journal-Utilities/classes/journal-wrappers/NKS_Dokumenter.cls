global class NKS_Dokumenter {
    @AuraEnabled
    public String tittel;
    @AuraEnabled
    public String brevkode;
    @AuraEnabled
    public List<NKS_Dokumentvarianter> dokumentvarianter;
}
