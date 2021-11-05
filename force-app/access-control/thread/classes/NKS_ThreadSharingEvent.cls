public without sharing class NKS_ThreadSharingEvent extends SharingEvent {
   
    public override void execute(Id recordId){
        List<Thread__c> threads=[SELECT Id, CRM_Account__c FROM Thread__c WHERE Id=:recordId];
        if(threads.size()>0){
            new NKS_ThreadAccessHandler().grantAccessToNewThreads(threads);
        }
    }
}
