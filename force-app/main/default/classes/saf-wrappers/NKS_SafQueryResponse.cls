public with sharing class NKS_SafQueryResponse {
    @AuraEnabled
    public Boolean isSuccess {
        get {
            return this.errors == null || this.errors.isEmpty() ? true : false;
        }
        set;
    }
    @AuraEnabled
    public List<NKS_SafError> errors;

    @AuraEnabled
    public NKS_SAFData data;

    public class NKS_SAFData {
        @AuraEnabled
        public NKS_SafDokumentoversikt dokumentoversiktBruker;
        @AuraEnabled
        public NKS_SafDokumentoversikt dokumentoversiktFagsak;
        @AuraEnabled
        public NKS_SafJournalpost journalpost;
        @AuraEnabled
        public List<NKS_SafJournalpost> tilknyttedeJournalposter;
        @AuraEnabled
        public List<NKS_SafJournalpost> dokumentoversiktJournalstatus;
        @AuraEnabled
        public List<NKS_SafSak> saker;
    }

    public NKS_SafQueryResponse() {
        this.errors = new List<NKS_SafError>();
    }
}
