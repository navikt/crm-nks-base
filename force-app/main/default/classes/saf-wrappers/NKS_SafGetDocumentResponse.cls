public with sharing class NKS_SafGetDocumentResponse {
    @AuraEnabled public Boolean isSuccess;
    @AuraEnabled public NKS_SafError error;
    @AuraEnabled public String documentString;
    @AuraEnabled public String contentType;
    @AuraEnabled public String contentDisposition;
}