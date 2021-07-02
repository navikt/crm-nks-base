public without sharing class NavTaskAccessService {
    public void grantAccess(List<NavTask__c> tasks, List<Person__c> persons) {
        Map<Integer, NavTask__c> navTaskByIndex = getNavTaskByIndex(tasks);
        List<SobjectWrapper> sobjects = new List<SobjectWrapper>();
        Map<Id, Person__c> personByTaskId = getPersonByTaskId(tasks, persons);
        if (personByTaskId != null && personByTaskId.size() > 0) {
            for (Integer index : navTaskByIndex .keySet()) {
                NavTask__c task = navTaskByIndex.get(index);
                Person__c person = personByTaskId.get(task.Id);
                if (person == null)
                    continue;
                SobjectWrapper wrapper = new SobjectWrapper();
                wrapper.recordIndex = index;
                wrapper.confidential = person.INT_Confidential__c;
                wrapper.isNavEmployee = person.INT_IsNavEmployee__c;
                wrapper.theme=task.NKS_Theme__r.CRM_Code__c;
                sobjects.add(wrapper);
            }

            List<NavTask__Share> shareRecords = new List<NavTask__Share>();
            List<ShareWrapper> shareWrappers = RecordShareService.grantAccess(sobjects, 'NavTask__c');
            for (ShareWrapper share : shareWrappers) {
                NavTask__Share taskShare = new NavTask__Share();
                NavTask__c task=navTaskByIndex.get(share.recordIndex);
                taskShare.ParentId = task.Id;
                taskShare.UserOrGroupId = share.publicGroupId;
                taskShare.AccessLevel = 'Edit';
                taskShare.RowCause = 'Manual';
                shareRecords.add(taskShare);
            }
            insert shareRecords;
        }
    }

    private Map<Integer, NavTask__c> getNavTaskByIndex(List<NavTask__c> tasks) {
        Map<Integer, NavTask__c> navTaskByIndex= new Map<Integer, NavTask__c>();

        //get ids
        Set<Id> taskIds=new Set<Id>();
        for (NavTask__c task : tasks) {
            taskIds.add(task.Id);
        }
        Integer i = 0;
        for (NavTask__c task :[SELECT Id, CRM_Account__c, NKS_Theme__r.CRM_Code__c FROM NavTask__c WHERE Id in:taskIds]) {
            navTaskByIndex.put(i, task);
            i++;
        }
        return navTaskByIndex;
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
