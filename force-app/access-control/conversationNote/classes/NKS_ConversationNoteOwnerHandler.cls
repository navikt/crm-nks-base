public with sharing class NKS_ConversationNoteOwnerHandler extends MyTriggers {
    public override void onBeforeInsert() {
        Id newOwnerId = RecordOwnerService.getDefaultOwner();

        if (newOwnerId != null) {
            for (Conversation_Note__c task : (List<Conversation_Note__c>) records) {
                if (task.CRM_Theme__c == null)
                    task.OwnerId = newOwnerId;
            }
        }
    }
}
