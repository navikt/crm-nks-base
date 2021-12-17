public with sharing class NKS_ThreadOwnerHandler extends MyTriggers {
    public override void onBeforeInsert() {
        Id newOwnerId = RecordOwnerService.getDefaultOwner();

        if (newOwnerId != null ) {
            for (Thread__c thread : (List<Thread__c>) records) {
                if(thread.CRM_Related_Object_Type__c!='Inquiry__c' && thread.CRM_Related_Object_Type__c!='Application__c'){
                    thread.OwnerId = newOwnerId;
                }
            }
        }
    }
}
