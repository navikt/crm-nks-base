global class NKS_ThreadAccessHandler extends MyTriggers {
    global override void onAfterInsert() {
        new NKS_ThreadAccessService().grantAccess((List<Thread__c>) records, getPersons(records));
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

    global override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<String> fieldNamesToCheck = new List<String>{};

        List<Id> parentIdToDelete = new List<Id>();
        List<Thread__c> threadsWithNewSharing = new List<Thread__c>();

        for (Thread__c thread : (List<Thread__c>) records) {
            Thread__c oldRecord = (Thread__c) triggerOldMap.get(thread.Id);
            if (MyTriggers.hasChangedFields(fieldNamesToCheck, thread, oldRecord)) {
                threadsWithNewSharing.add(thread);
            }
        }

        if (parentIdToDelete.size() > 0) {
            List<Thread__Share> toDelete = [
                SELECT Id
                FROM Thread__Share
                WHERE RowCause = 'Manual' AND ParentId IN :parentIdToDelete
            ];
            delete toDelete;
        }

        if (threadsWithNewSharing.size() > 0) {
            new NKS_ThreadAccessService().grantAccess(threadsWithNewSharing, getPersons(threadsWithNewSharing));
        }
    }
}
