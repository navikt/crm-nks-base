public with sharing class NavTaskAccessHandler extends MyTriggers {
    public override void onAfterInsert() {
        new NavTaskAccessService().grantAccess((List<NavTask__c>) records, getPersons(records));
    }

    private List<Person__c> getPersons(List<NavTask__c> tasks) {
        Set<Id> accountIds = new Set<id>();
        for (NavTask__c task : tasks) {
            accountIds.add(task.CRM_Account__c);
        }

        return [
            SELECT INT_Confidential__c, INT_IsNavEmployee__c, CRM_Account__c
            FROM Person__C
            WHERE CRM_Account__c IN :accountIds
        ];
    }
}
