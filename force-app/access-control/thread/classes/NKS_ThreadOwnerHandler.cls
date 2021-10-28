public with sharing class NKS_ThreadOwnerHandler extends MyTriggers {
    public override void onBeforeInsert() {
        Id newOwnerId = RecordOwnerService.getDefaultOwner();

        if (newOwnerId != null) {
            for (Thread__c task : (List<Thread__c>) records) {
                if (task.CRM_Theme__c == null)
                    task.OwnerId = newOwnerId;
            }
        }
    }
}
