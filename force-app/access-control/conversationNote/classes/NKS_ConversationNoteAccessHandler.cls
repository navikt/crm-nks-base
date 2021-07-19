
global class NKS_ConversationNoteAccessHandler extends MyTriggers {
    
    global override void onAfterInsert() {
        new NKS_ConversationNoteAccessService().grantAccess((List<Conversation_Note__c>) records, getPersons(records));
    }

    private List<Person__c> getPersons(List<Conversation_Note__c> notes) {
        Set<Id> accountIds = new Set<id>();
        for (Conversation_Note__c note : notes) {
            accountIds.add(note.CRM_Account__c);
        }

        return [
            SELECT INT_Confidential__c, INT_IsNavEmployee__c, CRM_Account__c
            FROM Person__C
            WHERE CRM_Account__c IN :accountIds
        ];
    }

    global override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<String> fieldNamesToCheck = new List<String>{
            'NKS_Incorrectly_Sent__c'
        };

        List<Id> parentIdToDelete = new List<Id>();
        List<Conversation_Note__c> notesWithNewSharing=new List<Conversation_Note__c>();

        for (Conversation_Note__c note : (List<Conversation_Note__c>) records) {
            Conversation_Note__c oldRecord = (Conversation_Note__c) triggerOldMap.get(note.Id);
            if (MyTriggers.hasChangedFields(fieldNamesToCheck, note, oldRecord)) {
                if(note.NKS_Incorrectly_Sent__c){
                    parentIdToDelete.add(note.Id);
                }
                else{
                    notesWithNewSharing.add(note);
                }
                
            }
        }

        if (parentIdToDelete.size() > 0) {
            List<Conversation_Note__Share> toDelete = [
                SELECT Id
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND ParentId IN :parentIdToDelete
            ];
            delete toDelete;
    }

    if(notesWithNewSharing.size()>0){
        new NKS_ConversationNoteAccessService().grantAccess(notesWithNewSharing, getPersons(notesWithNewSharing));
    }
}
}