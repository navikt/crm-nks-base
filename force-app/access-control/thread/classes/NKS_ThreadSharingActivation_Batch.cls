global class NKS_ThreadSharingActivation_Batch implements Database.Batchable<sObject> {
    global NKS_ThreadSharingActivation_Batch() {
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT CRM_Account__c, CRM_Henvendelse_BehandlingsId__c From Thread__c WHERE CRM_Account__c != null';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Thread__c> scope) {
        Set<Id> accountIds = new Set<Id>();
        for (Thread__c thread : scope) {
            accountIds.add(thread.CRM_Account__c);
        }

        List<Person__c> persons = [
            SELECT INT_Confidential__c, INT_IsNavEmployee__c, CRM_Account__c
            FROM Person__C
            WHERE CRM_Account__c IN :accountIds
        ];

        new NKS_ThreadAccessService().grantAccess(scope, persons);
    }

    global void finish(Database.BatchableContext bc) {
    }
}
