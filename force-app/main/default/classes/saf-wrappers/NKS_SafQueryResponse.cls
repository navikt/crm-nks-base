public with sharing class NKS_SafQueryResponse {
    @AuraEnabled public NKS_SafDokumentoversikt documentOverview;
    @AuraEnabled public Boolean isSuccess;
    @AuraEnabled public NKS_SafError error;
}