public with sharing class NKS_HomePageController {
    @AuraEnabled
    public static string getField(String type) {
        String information = [SELECT NKS_Information__c FROM NKS_Announcement__c WHERE NKS_Type__c =: type ORDER BY LastModifiedDate LIMIT 1].NKS_Information__c; 
        return information; 
    }

    @AuraEnabled
    public static List<SObject> getList(String type) {
        List<SObject> listtoreturn = new List<SObject>(); 
        return listtoreturn; 
    }
}
