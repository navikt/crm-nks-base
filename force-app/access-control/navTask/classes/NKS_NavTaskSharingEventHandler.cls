public without sharing class NKS_NavTaskSharingEventHandler extends SharingEvent {
   
    public override void execute(Id recordId){
        List<NavTask__c> tasks=[SELECT Id, CRM_Account__c, NKS_Theme__r.CRM_Code__c FROM NavTask__c WHERE Id=:recordId];
        if(tasks.size()>0){
            new NavTaskAccessHandler().grantAccessToNewTasks(tasks);
        }
    }
}
