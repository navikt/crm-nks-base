public with sharing class NKS_TaskOwnerHandler extends MyTriggers {
    public override void onBeforeInsert() {

        Id newOwnerId=RecordOwnerService.getDefaultOwner();

        if(newOwnerId!=null){
           for(NavTask__c task:(List<NavTask__c>) records){
               if(task.CRM_Theme__c==null)
                task.OwnerId=newOwnerId;
           }            
        }
    }
}
