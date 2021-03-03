@isTest
public class NKS_NavTaskTriggerHandler_Test {
    @TestSetup
    static void makeData() {
        UTIL_TestDataFactory.createRecord(new NavTask__c(CRM_Comments__c = 'TEST VALUE'));
    }

    @isTest
    static void testCommentTracking() {
        NavTask__c taskToUpdate = [SELECT Id, CRM_Comments__c FROM NavTask__c LIMIT 1];

        taskToUpdate.CRM_Comments__c = 'NEW TEST VALUE';
        Test.startTest();
        update taskToUpdate;
        Test.stopTest();

        System.assertEquals(
            'TEST VALUE',
            [SELECT Id, Body FROM FeedItem WHERE ParentId = :taskToUpdate.Id LIMIT 1]
            ?.Body
        );
    }
}
