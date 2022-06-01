global class NKS_Aktoer {
    @AuraEnabled
    public String aktoertype {
        get;
        set {
            aktoertype = String.isNotBlank(value) ? value.trim() : value;
        }
    }
    @AuraEnabled
    public String ident;
    @AuraEnabled
    public String navn {
        get;
        set {
            navn = String.isNotBlank(value) ? value.trim() : value;
        }
    }
}
