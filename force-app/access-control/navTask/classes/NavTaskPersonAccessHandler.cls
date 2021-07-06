public with sharing class NavTaskPersonAccessHandler extends MyTriggers {
    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<String> fieldNamesToCheck = new List<String>{ 'INT_Confidential__c', 'INT_IsNavEmployee__c' };
        Set<Id> personIdsWithNewSharing = new Set<Id>();

        for (Person__c person : (List<Person__c>) records) {
            Person__c oldRecord = (Person__c) triggerOldMap.get(person.Id);
            if (MyTriggers.hasChangedFields(fieldNamesToCheck, person, oldRecord)) {
                personIdsWithNewSharing.add(person.Id);
            }
        }

        List<NavTask__c> tasks = getTasksFromPersonIds(personIdsWithNewSharing);
        Set<Id> navTaskIds = new Set<Id>();
        for (NavTask__c t : tasks) {
            navTaskIds.add(t.Id);
        }

        if (personIdsWithNewSharing.size() > 0) {
            List<NavTask__Share> toDelete = [
                SELECT Id
                FROM NavTask__Share
                WHERE RowCause = 'Manual' AND ParentId IN :navTaskIds
            ];

            delete toDelete;
            new NavTaskAccessService().grantAccess(tasks, records);
        }
    }

    private List<NavTask__c> getTasksFromPersonIds(Set<Id> personIds) {
        return [SELECT Id, CRM_Account__c, NKS_Theme__r.CRM_Code__c FROM NavTask__c WHERE CRM_Account__r.CRM_Person__c IN :personIds];
    }
}
