public with sharing class NKS_HomePageController {
    @AuraEnabled
    public static string getField(String type) {
        String information = [SELECT NKS_Information__c FROM NKS_Announcement__c WHERE NKS_Type__c =: type ORDER BY LastModifiedDate DESC LIMIT 1].NKS_Information__c; 
        return information; 
    }

    @AuraEnabled
    public static List<SObject> getList(String type) {
        List<SObject> listtoreturn = new List<SObject>(); 
        //todo: fix
        return listtoreturn; 
    }

    List<NKS_HomePageController.homePageItem> items = new List<NKS_HomePageController.homePageItem>(); 
    for(NKS_Announcement__c a : [SELECT Id, Name FROM NKS_Announcement__c]){
            items.add(new homePageItem(a.Id, a.Name));
    }
    return items;

    public class homePageItem{
        @AuraEnabled
        public Id RecordId {get;set;}
        @AuraEnabled
        public string Name {get;set;}

        public homePageItem(Id recordId, String name){
            this.RecordId=recordId;
            this.Name=name;
        }
    }
}
