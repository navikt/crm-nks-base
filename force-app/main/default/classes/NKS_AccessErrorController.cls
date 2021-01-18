public with sharing class NKS_AccessErrorController {
    @AuraEnabled
    public static String checkAccess(Id recordId , String objectApiName){
        Id userId = UserInfo.getUserId();
        Id personId; 
        if(objectApiName == 'Case') personId = [SELECT Account.CRM_Person__c FROM Case WHERE Id =: recordId]?.Account.CRM_Person__c; 
        else if(objectApiName == 'Account') personId = [SELECT CRM_Person__c FROM Account WHERE Id =: recordId]?.CRM_Person__c; 
        
        Boolean access = false; 
        if(personId != null){
            access = [SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE UserId =: userId AND RecordId =: personId].HasReadAccess;
        }
        if(access) return null; 
        else return 'Du mangler tilgang til å se informasjon knyttet til denne brukeren'; 
    }
}