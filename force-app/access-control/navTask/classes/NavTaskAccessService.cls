public without sharing class NavTaskAccessService {
    public void grantAccess(List<NavTask__c> tasks, List<Person__c> persons) {
        Map<Integer, Id> recordIdByIndex = getRecordIdByIndex(tasks);
        List<SobjectWrapper> sobjects = new List<SobjectWrapper>();
        Map<Id, Person__c> personByTaskId = getPersonByTaskId(tasks, persons);
        if (personByTaskId != null && personByTaskId.size() > 0) {
            for (Integer index : recordIdByIndex.keySet()) {
                Id taskId = recordIdByIndex.get(index);
                Person__c person = personByTaskId.get(taskId);
                if (person == null)
                    continue;
                SobjectWrapper wrapper = new SobjectWrapper();
                wrapper.recordIndex = index;
                wrapper.confidential = person.INT_Confidential__c;
                wrapper.isNavEmployee = person.INT_IsNavEmployee__c;
                sobjects.add(wrapper);
            }

            List<NavTask__Share> shareRecords = new List<NavTask__Share>();
            List<ShareWrapper> shareWrappers = RecordShareService.grantAccess(sobjects, 'NavTask__c');
            for (ShareWrapper share : shareWrappers) {
                NavTask__Share taskShare = new NavTask__Share();
                taskShare.ParentId = recordIdByIndex.get(share.recordIndex);
                taskShare.UserOrGroupId = share.publicGroupId;
                taskShare.AccessLevel = 'Edit';
                taskShare.RowCause = 'Manual';
                shareRecords.add(taskShare);
            }
            insert shareRecords;
        }
    }

    private Map<Integer, Id> getRecordIdByIndex(List<NavTask__c> tasks) {
        Map<Integer, Id> recordIdByIndex = new Map<Integer, Id>();
        Integer i = 0;
        for (NavTask__c task : tasks) {
            recordIdByIndex.put(i, task.Id);
            i++;
        }
        return recordIdByIndex;
    }

    private Map<Id, Person__c> getPersonByTaskId(List<NavTask__c> tasks, List<Person__c> persons) {
        Set<Id> accountIds = new Set<id>();
        for (NavTask__c task : tasks) {
            accountIds.add(task.CRM_Account__c);
        }

        Map<Id, Person__c> personByAccountId = new Map<Id, Person__c>();
        for (Person__c person : persons) {
            personByAccountId.put(person.CRM_Account__c, person);
        }

        Map<Id, Person__c> personByTaskId = new Map<Id, Person__c>();
        for (NavTask__c task : tasks) {
            Person__c person = personByAccountId.get(task.CRM_Account__c);
            if (person != null) {
                personByTaskId.put(task.Id, person);
            }
        }
        return personByTaskId;
    }
}
