public with sharing class NKS_SafError {
    @AuraEnabled
    public DateTime timestamp;
    @AuraEnabled
    public Integer status;
    @AuraEnabled
    public String error;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String path;
}
