global class NKS_JournalEntryWrapper {
    @AuraEnabled
    public String tittel;
    @AuraEnabled
    public String journalpostType;
    @AuraEnabled
    public String tema;
    @AuraEnabled
    public String behandlingstema;
    @AuraEnabled
    public String kanal;
    @AuraEnabled
    public String journalfoerendeEnhet;
    @AuraEnabled
    public NKS_AvsenderMottaker avsenderMottaker;
    @AuraEnabled
    public NKS_Bruker bruker;
    @AuraEnabled
    public NKS_Sak sak;
    @AuraEnabled
    public List<NKS_Dokumenter> dokumenter;

    public NKS_JournalEntryWrapper() {
    }
}
