public without sharing class NKS_ThreadSharingEventHandler extends SharingEvent {
   
    public override void execute(Id recordId){
        List<Thread__c> threads=[SELECT Id, CRM_Account__c, CRM_Henvendelse_BehandlingsId__c FROM Thread__c WHERE Id=:recordId];
        system.debug('#' + threads.size());
        if(threads.size()>0){
            new NKS_ThreadAccessHandler().grantAccessToNewThreads(threads);
        }
    }
}
