public with sharing class NKS_ThreadOwnerHandler extends MyTriggers {
    public override void onBeforeInsert() {
        Id newOwnerId = RecordOwnerService.getDefaultOwner();

        if (newOwnerId != null) {
            for (Thread__c thread : (List<Thread__c>) records) {
                thread.OwnerId = newOwnerId;
            }
        }
    }
}
