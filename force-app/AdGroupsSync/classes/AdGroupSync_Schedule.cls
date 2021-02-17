/* crate async request jobb for each group who should be synced */
public with sharing class AdGroupSync_Schedule implements Schedulable {

    public void execute( SchedulableContext sc ) {

        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

        List<AdGroupMapping__mdt> mappings=[SELECT AdGroupIdPreprod__c, AdGroupIdProd__c, SalesforceGroupDeveloperName__c  FROM AdGroupMapping__mdt];

        Map<String,Id> publicGroupIdByDeveloperName=getSalesforcePublicGroups(mappings);

        List<AsyncRequest__c> requests=new List<AsyncRequest__c>();
        for(AdGroupMapping__mdt m:mappings){
            Id salesforceGroupId=publicGroupIdByDeveloperName.get(m.SalesforceGroupDeveloperName__c);
            String adGroupId=runningInASandbox ? m.AdGroupIdPreprod__c : m.AdGroupIdProd__c;

            AsyncRequest__c req=new AsyncRequest__c();
            req.CRM_ApexJobType__c='Queueable';
            req.CRM_AsyncType__c='AdGroupSync';
            req.CRM_Params__c=salesforceGroupId + ', ' + adGroupId;
            requests.add(req);
        }

        insert requests;
    }

    private Map<String, Id> getSalesforcePublicGroups(List<AdGroupMapping__mdt> mappings){
        Set<String> developerNames=new Set<String>(); 
        for(AdGroupMapping__mdt m:mappings){
            developerNames.add(m.SalesforceGroupDeveloperName__c);
         }

         Map<String,Id> publicGroupIdByDeveloperName=new Map<String,Id>();
         for(Group publicGroup:[SELECT Id, DeveloperName FROM Group WHERE DeveloperName in:developerNames]){
             publicGroupIdByDeveloperName.put(publicGroup.DeveloperName, publicGroup.Id);
         }
         return publicGroupIdByDeveloperName;
    }
}