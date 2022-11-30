global class NKS_ThreadAccessHandler extends MyTriggers {
    
    private static final List<String> threadTypesOfInterest = new List<String>{'STO', 'STB'};

    global override void onAfterUpdate(Map<Id, sObject> triggerOldMap){
        List<String> fieldNamesToCheck = new List<String>{ 'CRM_Theme__c'};
        List<Id> parentIdToDelete = new List<Id>();
        List<Thread__c> threadsWithNewSharing = new List<Thread__c>();

        for(Thread__c thread : (List<Thread__c>)records){
            if(
                threadTypesOfInterest.contains(thread.CRM_Thread_Type__c) &&
                MyTriggers.hasChangedFields(fieldNamesToCheck, thread, triggerOldMap.get(thread.Id))
            ){
                parentIdToDelete.add(thread.Id);
                threadsWithNewSharing.add(thread);
            }
        }

        if(parentIdToDelete.size() > 0){
            List<Thread__Share> toDelete = [
                SELECT Id
                FROM Thread__Share
                WHERE RowCause = 'Manual' AND ParentId IN :parentIdToDelete
            ];
            new CRM_DatabaseOperations().setNumberOfRetries(1).setDomain(CRM_ApplicationDomain.Domain.NKS).deleteRecords(toDelete);
        }

        if(threadsWithNewSharing.size() > 0){
            new NKS_ThreadAccessService().grantAccess(threadsWithNewSharing, getPersons(threadsWithNewSharing));
        }
    }

    global override void onAfterInsert() {
        List<RecordSharingEvent__e> events = new List<RecordSharingEvent__e>();
        //run sharing in a platform event

        for (Thread__c thread : (List<Thread__c>) records) {
            if (
                threadTypesOfInterest.contains(thread.CRM_Thread_Type__c)
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