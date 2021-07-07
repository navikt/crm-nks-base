public with sharing class NKS_TaskOwnerHandler extends MyTriggers {
    public override void onBeforeInsert() {

        Id newOwnerId=RecordOwnerService.getDefaultOwner();

        if(newOwnerId!=null){
           for(NavTask__c task:(List<NavTask__c>) records){
               task.OwnerId=newOwnerId;
           }            
        }
    }
}
