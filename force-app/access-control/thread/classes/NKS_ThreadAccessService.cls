public without sharing class NKS_ThreadAccessService {
    public void grantAccess(List<Thread__c> threads, List<Person__c> persons) {
        Map<Integer, Thread__c> ThreadByIndex = getThreadByIndex(threads);
        List<SobjectWrapper> sobjects = new List<SobjectWrapper>();
        Map<Id, Person__c> personByThreadId = getPersonByThreadId(threads, persons);
        if (personByThreadId != null && personByThreadId.size() > 0) {
            for (Integer index : ThreadByIndex.keySet()) {
                Thread__c thread = ThreadByIndex.get(index);
                Person__c person = personByThreadId.get(thread.Id);
                if (person == null)
                    continue;
                SobjectWrapper wrapper = new SobjectWrapper();
                wrapper.recordIndex = index;
                wrapper.confidential = person.INT_Confidential__c;
                wrapper.isNavEmployee = person.INT_IsNavEmployee__c;
                wrapper.externalId = thread.CRM_Henvendelse_BehandlingsId__c;
                sobjects.add(wrapper);
            }

            List<Thread__Share> shareRecords = new List<Thread__Share>();
            List<ShareWrapper> shareWrappers = RecordShareService.grantAccess(sobjects, 'Thread__c');
            for (ShareWrapper share : shareWrappers) {
                Thread__Share threadShare = new Thread__Share();
                Thread__c thread = ThreadByIndex.get(share.recordIndex);
                threadShare.ParentId = thread.Id;
                threadShare.UserOrGroupId = share.publicGroupId;
                threadShare.AccessLevel = 'Edit';
                threadShare.RowCause = 'Manual';
                shareRecords.add(threadShare);
            }
            insert shareRecords;
        }
    }

    private Map<Integer, Thread__c> getThreadByIndex(List<Thread__c> threads) {
        Map<Integer, Thread__c> ThreadByIndex = new Map<Integer, Thread__c>();
        Integer i = 0;
        for (Thread__c thread : threads) {
            ThreadByIndex.put(i, thread);
            i++;
        }
        return ThreadByIndex;
    }

    private Map<Id, Person__c> getPersonByThreadId(List<Thread__c> threads, List<Person__c> persons) {
        Set<Id> accountIds = new Set<id>();
        for (Thread__c thread : threads) {
            accountIds.add(thread.CRM_Account__c);
        }

        Map<Id, Person__c> personByAccountId = new Map<Id, Person__c>();
        for (Person__c person : persons) {
            personByAccountId.put(person.CRM_Account__c, person);
        }

        Map<Id, Person__c> personByThreadId = new Map<Id, Person__c>();
        for (Thread__c thread : threads) {
            Person__c person = personByAccountId.get(thread.CRM_Account__c);
            if (person != null) {
                personByThreadId.put(thread.Id, person);
            }
        }
        return personByThreadId;
    }
}
