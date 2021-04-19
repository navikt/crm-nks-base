global class NavTaskBatcher implements Database.Batchable<sObject> {
    private String query = 'SELECT Id, INT_External_Reference__c, CRM_Comments__c, NKS_Comments__c, RecordTypeId, NKS_Is_Person_Account__c FROM NavTask__c WHERE INT_External_Reference__c != null';
    private final Id PERSON_TASK_RECORD_TYPE_ID = Schema.SObjectType.NavTask__c.getRecordTypeInfosByDeveloperName()
        .get('NKS_Person_Task')
        .getRecordTypeId();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        for (NavTask__c navTask : (List<NavTask__c>) scope) {
            navTask.NKS_Comments__c = String.isBlank(navTask.NKS_Comments__c)
                ? navTask.CRM_Comments__c
                : navTask.NKS_Comments__c;
            if (navTask.NKS_Is_Person_Account__c == true)
                navTask.RecordTypeId = PERSON_TASK_RECORD_TYPE_ID;
        }
        update scope;
    }

    global void finish(Database.BatchableContext BC) {
    }
}
