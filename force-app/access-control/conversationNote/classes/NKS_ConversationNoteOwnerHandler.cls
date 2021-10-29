public with sharing class NKS_ConversationNoteOwnerHandler extends MyTriggers {
    public override void onBeforeInsert() {
        Id newOwnerId = RecordOwnerService.getDefaultOwner();

        if (newOwnerId != null) {
            for (Conversation_Note__c note : (List<Conversation_Note__c>) records) {
                note.OwnerId = newOwnerId;
            }
        }
    }
}
