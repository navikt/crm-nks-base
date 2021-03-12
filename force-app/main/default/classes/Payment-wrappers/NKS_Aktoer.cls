global class NKS_Aktoer {
    @AuraEnabled
    public String aktoerId;
    @AuraEnabled
    public String navn {
        get;
        set {
            navn = String.isNotBlank(value) ? value.trim() : value;
        }
    }
}
