public without sharing class NKS_ThreadAccessService {
    private final Integer numberOfRetries = 1;

    // Updates access rights for threads
    public void grantAccess(List<Thread__c> threads, List<Person__c> persons) {
        List<SobjectWrapper> sobjects = new List<SobjectWrapper>();
        Map<Id, Person__c> personByThreadId = getPersonByThreadId(threads, persons);
        if (personByThreadId != null && personByThreadId.size() > 0) {
            for (Integer i = 0; i < threads.size(); i++) {
                Thread__c thread = threads[i];
                Person__c person = personByThreadId.get(thread.Id);
                if (person == null)
                    continue;
                SobjectWrapper wrapper = new SobjectWrapper();
                wrapper.recordIndex = i;
                wrapper.confidential = person.INT_Confidential__c;
                wrapper.isNavEmployee = person.INT_IsNavEmployee__c;
                wrapper.externalId = thread.CRM_Henvendelse_BehandlingsId__c;
                wrapper.officeRestriction = thread.CRM_Office_Restriction__c;
                wrapper.theme = thread.CRM_Theme_Code__c;
                wrapper.category = thread.CRM_Thread_Type__c == 'CHAT'
                    ? thread.CRM_Theme_Group_Name__c
                    : thread.STO_Category__c;
                sobjects.add(wrapper);
            }

            List<Thread__Share> shareRecords = new List<Thread__Share>();
            List<ShareWrapper> shareWrappers = RecordShareService.grantAccess(sobjects, 'Thread__c');
            for (ShareWrapper share : shareWrappers) {
                Thread__Share threadShare = new Thread__Share();
                Thread__c thread = threads[share.recordIndex];
                threadShare.ParentId = thread.Id;
                threadShare.UserOrGroupId = share.publicGroupId;
                threadShare.AccessLevel = 'Edit';
                threadShare.RowCause = 'Manual';
                shareRecords.add(threadShare);
            }
            new CRM_DatabaseOperations()
                .setNumberOfRetries(1)
                .setDomain(CRM_ApplicationDomain.Domain.NKS)
                .insertRecords(shareRecords);
        }
    }

    // Creates a map of Person objects by Thread Id
    private Map<Id, Person__c> getPersonByThreadId(List<Thread__c> threads, List<Person__c> persons) {
        Map<Id, Person__c> personByAccountId = new Map<Id, Person__c>();
        for (Person__c person : persons) {
            personByAccountId.put(person.CRM_Account__c, person);
        }

        Map<Id, Person__c> personByThreadId = new Map<Id, Person__c>();
        for (Thread__c thread : threads) {
            Person__c threadPerson = personByAccountId.containsKey(thread.CRM_Account__c)
                ? personByAccountId.get(thread.CRM_Account__c)
                : null;
            if (threadPerson != null)
                personByThreadId.put(thread.Id, threadPerson);
        }
        return personByThreadId;
    }
}
