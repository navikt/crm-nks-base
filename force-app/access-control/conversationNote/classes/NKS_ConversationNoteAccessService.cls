public without sharing class NKS_ConversationNoteAccessService {
    public void grantAccess(List<Conversation_Note__c> notes, List<Person__c> persons) {
        Map<Integer, Conversation_Note__c> conversationNoteByIndex = getConversationNoteByIndex(notes);
        List<SobjectWrapper> sobjects = new List<SobjectWrapper>();
        Map<Id, Person__c> personByConversationNoteId = getPersonByConversationNoteId(notes, persons);
        if (personByConversationNoteId != null && personByConversationNoteId.size() > 0) {
            for (Integer index : conversationNoteByIndex.keySet()) {
                Conversation_Note__c note = conversationNoteByIndex.get(index);
                Person__c person = personByConversationNoteId.get(note.Id);
                if (person == null)
                    continue;
                SobjectWrapper wrapper = new SobjectWrapper();
                wrapper.recordIndex = index;
                wrapper.confidential = person.INT_Confidential__c;
                wrapper.isNavEmployee = person.INT_IsNavEmployee__c;
                wrapper.incorrectlySent = note.NKS_Incorrectly_Sent__c;
                wrapper.externalId = note.CRM_Henvendelse_BehandlingsId__c;
                wrapper.officeRestriction = note.CRM_Office_Restriction__c;
                wrapper.theme = note.CRM_Theme_Code__c;
                sobjects.add(wrapper);
            }

            List<Conversation_Note__Share> shareRecords = new List<Conversation_Note__Share>();
            List<ShareWrapper> shareWrappers = RecordShareService.grantAccess(sobjects, 'Conversation_Note__c');
            for (ShareWrapper share : shareWrappers) {
                Conversation_Note__Share noteShare = new Conversation_Note__Share();
                Conversation_Note__c note = ConversationNoteByIndex.get(share.recordIndex);
                noteShare.ParentId = note.Id;
                noteShare.UserOrGroupId = share.publicGroupId;
                noteShare.AccessLevel = 'Edit';
                noteShare.RowCause = 'Manual';
                shareRecords.add(noteShare);
            }
            insert shareRecords;
        }
    }

    private Map<Integer, Conversation_Note__c> getConversationNoteByIndex(List<Conversation_Note__c> notes) {
        Map<Integer, Conversation_Note__c> conversationNoteByIndex = new Map<Integer, Conversation_Note__c>();
        Integer i = 0;
        for (Conversation_Note__c note : notes) {
            conversationNoteByIndex.put(i, note);
            i++;
        }
        return conversationNoteByIndex;
    }

    private Map<Id, Person__c> getPersonByConversationNoteId(
        List<Conversation_Note__c> notes,
        List<Person__c> persons
    ) {
        Set<Id> accountIds = new Set<id>();
        for (Conversation_Note__c note : notes) {
            accountIds.add(note.CRM_Account__c);
        }

        Map<Id, Person__c> personByAccountId = new Map<Id, Person__c>();
        for (Person__c person : persons) {
            personByAccountId.put(person.CRM_Account__c, person);
        }

        Map<Id, Person__c> personByNoteId = new Map<Id, Person__c>();
        for (Conversation_Note__c note : notes) {
            Person__c person = personByAccountId.get(note.CRM_Account__c);
            if (person != null) {
                personByNoteId.put(note.Id, person);
            }
        }
        return personByNoteId;
    }
}
