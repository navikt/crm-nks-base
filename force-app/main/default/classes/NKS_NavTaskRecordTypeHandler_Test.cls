@isTest
public class NKS_NavTaskRecordTypeHandler_Test {
    private static final Id PERSON_ACCOUNT_RCT_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('PersonAccount')
        .getRecordTypeId();
    private static final Id PERSON_TASK_RECORD_TYPE_ID = Schema.SObjectType.NavTask__c.getRecordTypeInfosByDeveloperName()
        .get('NKS_Person_Task')
        .getRecordTypeId();

    @TestSetup
    static void makeData() {
        UTIL_TestDataFactory.createRecord(new Person__c(Name = '12345678911'));
    }

    @isTest
    static void testSetRecordType() {
        Account acc = [SELECT Id FROM Account WHERE IsPersonAccount = TRUE LIMIT 1];

        Test.startTest();
        UTIL_TestDataFactory.createRecord(new NavTask__c(CRM_Account__c = acc.Id));
        Test.stopTest();

        NavTask__c navTask = [SELECT Id, RecordTypeId FROM NavTask__c LIMIT 1];

        System.assertEquals(PERSON_TASK_RECORD_TYPE_ID, navTask.RecordTypeId);
    }
}
