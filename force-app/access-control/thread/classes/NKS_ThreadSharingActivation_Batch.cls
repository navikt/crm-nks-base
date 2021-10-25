global class NKS_ThreadSharingActivation_Batch implements Database.Batchable<sObject> {
    global NKS_ThreadSharingActivation_Batch() {
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT CRM_Account__r.CRM_Person__c From Thread__c WHERE CRM_Account__r.CRM_Person__c != null';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Thread__c> scope) {
        Id veilederGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME
            LIMIT 1
        ]
        .Id;
        Id skjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.SKJERMET_GROUP_NAME
            LIMIT 1
        ]
        .Id;
        Id fortroligGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.FORTOLIG_GROUP_NAME
            LIMIT 1
        ]
        .Id;

        Set<Id> personIds = new Set<Id>();
        for (Thread__c thread : scope) {
            personIds.add(thread.CRM_Account__r.CRM_Person__c);
        }

        Map<Id, Person__c> personById = new Map<Id, Person__c>();
        for (Person__c person : [
            SELECT Id, INT_Confidential__c, INT_IsNavEmployee__c
            FROM Person__c
            WHERE Id IN :personIds
        ]) {
            personById.put(person.Id, person);
        }

        List<Thread__Share> shareRecords = new List<Thread__Share>();
        for (Thread__c thread : scope) {
            Person__c person = personById.get(thread.CRM_Account__r.CRM_Person__c);
            Id groupId;
            if (person.INT_Confidential__c == 'UGRADERT' && person.INT_IsNavEmployee__c == false) {
                groupId = veilederGroupId;
            } else if (person.INT_Confidential__c == 'UGRADERT' && person.INT_IsNavEmployee__c == true) {
                groupId = skjermetGroupId;
            } else if (person.INT_Confidential__c == 'FORTROLIG') {
                groupId = fortroligGroupId;
            }

            Thread__Share share = new Thread__Share();
            share.ParentId = thread.Id;
            share.UserOrGroupId = groupId;
            share.AccessLevel = 'Edit';
            share.RowCause = 'Manual';
            shareRecords.add(share);
        }
        Database.insert(shareRecords, false);
    }

    global void finish(Database.BatchableContext bc) {
    }
}
