global class NKS_ConversationNotePersonAccessHandler  extends MyTriggers {
     global override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        
        List<String> fieldNamesToCheck = new List<String>{ 'INT_Confidential__c', 'INT_IsNavEmployee__c' };
        Set<Id> personIdsWithNewSharing = new Set<Id>();

        for (Person__c person : (List<Person__c>) records) {
            Person__c oldRecord = (Person__c) triggerOldMap.get(person.Id);
            if (MyTriggers.hasChangedFields(fieldNamesToCheck, person, oldRecord)) {
                personIdsWithNewSharing.add(person.Id);
            }
        }

        List<Conversation_Note__c> notes = getConversationNotesFromPersonIds(personIdsWithNewSharing);
        Set<Id> conversationNoteIds = new Set<Id>();
        for (Conversation_Note__c cn : notes) {
            conversationNoteIds.add(cn.Id);
        }

        if (personIdsWithNewSharing.size() > 0) {
            List<Conversation_Note__Share> toDelete = [
                SELECT Id
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND ParentId IN :conversationNoteIds
            ];

            delete toDelete;
            new NKS_ConversationNoteAccessService().grantAccess(notes, records);
        }
    }

    private List<Conversation_Note__c> getConversationNotesFromPersonIds(Set<Id> personIds) {
        return [SELECT Id, CRM_Account__c, NKS_Incorrectly_Sent__c, CRM_Henvendelse_BehandlingsId__c FROM Conversation_Note__c WHERE CRM_Account__r.CRM_Person__c IN :personIds AND CRM_Henvendelse_BehandlingsId__c=null];
    }
}
