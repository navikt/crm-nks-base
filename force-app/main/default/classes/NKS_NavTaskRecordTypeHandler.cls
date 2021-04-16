global class NKS_NavTaskRecordTypeHandler extends MyTriggers {
    private final Id PERSON_TASK_RECORD_TYPE_ID = Schema.SObjectType.NavTask__c.getRecordTypeInfosByDeveloperName()
        .get('NKS_Person_Task')
        .getRecordTypeId();

    global override void onBeforeInsert() {
        for (NavTask__c navTask : (List<NavTask__c>) Records) {
            if (navTask.NKS_Is_Person_Account__c) {
                navTask.RecordTypeId = PERSON_TASK_RECORD_TYPE_ID;
            }
        }
    }
}
