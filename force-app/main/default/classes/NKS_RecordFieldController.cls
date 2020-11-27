public with sharing class NKS_RecordFieldController {
    @AuraEnabled
    public static string getField(String type) {
        String information = [SELECT NKS_Information__c FROM NKS_Announcement__c WHERE NKS_Type__c =: type ORDER BY LastModifiedDate LIMIT 1].NKS_Information__c; 
        return information; 
    }
}
