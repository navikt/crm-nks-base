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
    }

    public NKS_SafQueryResponse() {
        this.errors = new List<NKS_SafError>();
    }
}
