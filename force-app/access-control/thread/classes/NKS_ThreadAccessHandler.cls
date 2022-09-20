global class NKS_ThreadAccessHandler extends MyTriggers {
    global override void onAfterInsert() {
        List<RecordSharingEvent__e> events = new List<RecordSharingEvent__e>();
        //run sharing in a platform event

        for (Thread__c thread : (List<Thread__c>) records) {
            if (
                thread.CRM_Related_Object_Type__c != 'Inquiry__c' &&
                thread.CRM_Related_Object_Type__c != 'Application__c'
            ) {
                RecordSharingEvent__e event = new RecordSharingEvent__e();
                event.RecordId__c = thread.Id;
                event.ObjectType__c = 'Thread__c';
                events.add(event);
            }
        }

        if (events.size() > 0) {
            EventBus.publish(events);
        }
    }

    public void grantAccessToNewThreads(List<Thread__c> threads) {
        new NKS_ThreadAccessService().grantAccess(threads, getPersons(threads));
    }

    private List<Person__c> getPersons(List<Thread__c> threads) {
        Set<Id> accountIds = new Set<id>();
        for (Thread__c thread : threads) {
            accountIds.add(thread.CRM_Account__c);
        }

        return [
            SELECT INT_Confidential__c, INT_IsNavEmployee__c, CRM_Account__c
            FROM Person__C
            WHERE CRM_Account__c IN :accountIds
        ];
    }
}